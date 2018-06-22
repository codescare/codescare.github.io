---
title: "TPU without Estimator"
date: 2018-06-22T21:21:52+05:30
---

If you're using Tensorflow to train a deep learning model that takes hours to run on good hardware, chances are that you've heard of Google's latest cloud offering - the Tensor Processing Unit (TPU). [According to Google](https://cloudplatform.googleblog.com/2017/04/quantifying-the-performance-of-the-TPU-our-first-machine-learning-chip.html), these ASICs can be 15x to 30x faster than the hardware you are currently using.

However, if you glance at the documentation for using cloud TPUs with TensorFlow, you will find that Google always refers you to use the [Estimator](https://www.tensorflow.org/programmers_guide/estimators) API, which is a high level API built on top of the lower level [Graph and Session APIs](https://www.tensorflow.org/programmers_guide/low_level_intro). While it is advisable using this API since it probably *will* perform better than your code in low level APIs, being written with things such as TPUs in mind, but there are still situations where you may want a performance boost on your old code that uses the old low level APIs. So I'm going to quickly summarise below how I ran my old model with only a few lines of changes on a cloud TPU.

**Note:** If you're not familiar with the basics of Google Cloud, I encourage reading my post on [Google Cloud Basics](../google-cloud-basics) and/or other documentation/tutorials first.

> **DISCLAIMER**: The author of this article is a 19 year old kid messing around with cloud infrastructure, i.e. me. I'm not responsible for anything bad that happens due to you doing any of this. Reader discretion is advised :)

# A Simple Model

I will be using a toy problem pragarized from [here](https://gist.github.com/vinhkhuc/e53a70f9e5c3f55852b0) to demonstrate how we can make it use TPUs with just a few additionaly lines of code. So here is a simple neural network. Note that I'm using TensorFlow 1.8, the latest version as of writing this.

```python
# Implementation of a simple MLP network with one hidden layer. Tested on the iris data set.
# Requires: numpy, sklearn>=0.18.1, tensorflow>=1.0

# NOTE: In order to make the code simple, we rewrite x * W_1 + b_1 = x' * W_1'
# where x' = [x | 1] and W_1' is the matrix W_1 appended with a new row with elements b_1's.
# Similarly, for h * W_2 + b_2
import tensorflow as tf
import numpy as np
from sklearn import datasets
from sklearn.model_selection import train_test_split

RANDOM_SEED = 42
tf.set_random_seed(RANDOM_SEED)


def init_weights(shape):
    """ Weight initialization """
    weights = tf.random_normal(shape, stddev=0.1)
    return tf.Variable(weights)

def forwardprop(X, w_1, w_2):
    """
    Forward-propagation.
    IMPORTANT: yhat is not softmax since TensorFlow's softmax_cross_entropy_with_logits() does that internally.
    """
    h    = tf.nn.sigmoid(tf.matmul(X, w_1))  # The \sigma function
    yhat = tf.matmul(h, w_2)  # The \varphi function
    return yhat

def get_iris_data():
    """ Read the iris data set and split them into training and test sets """
    iris   = datasets.load_iris()
    data   = iris["data"]
    target = iris["target"]

    # Prepend the column of 1s for bias
    N, M  = data.shape
    all_X = np.ones((N, M + 1))
    all_X[:, 1:] = data

    # Convert into one-hot vectors
    num_labels = len(np.unique(target))
    all_Y = np.eye(num_labels)[target]  # One liner trick!
    return train_test_split(all_X, all_Y, test_size=0.33, random_state=RANDOM_SEED)

def main():
    train_X, test_X, train_y, test_y = get_iris_data()

    # Layer's sizes
    x_size = train_X.shape[1]   # Number of input nodes: 4 features and 1 bias
    h_size = 256                # Number of hidden nodes
    y_size = train_y.shape[1]   # Number of outcomes (3 iris flowers)

    # Symbols
    X = tf.placeholder("float", shape=[None, x_size])
    y = tf.placeholder("float", shape=[None, y_size])

    # Weight initializations
    w_1 = init_weights((x_size, h_size))
    w_2 = init_weights((h_size, y_size))

    # Forward propagation
    yhat    = forwardprop(X, w_1, w_2)
    predict = tf.argmax(yhat, axis=1)

    # Backward propagation
    cost    = tf.reduce_mean(tf.nn.softmax_cross_entropy_with_logits(labels=y, logits=yhat))
    updates = tf.train.GradientDescentOptimizer(0.01).minimize(cost)

    # Run SGD
    with tf.Session() as sess:
        init = tf.global_variables_initializer()
        sess.run(init)

        for epoch in range(100):
            # Train with each example
            for i in range(len(train_X)):
                sess.run(updates, feed_dict={X: train_X[i: i + 1], y: train_y[i: i + 1]})

            train_accuracy = np.mean(np.argmax(train_y, axis=1) ==
                                     sess.run(predict, feed_dict={X: train_X, y: train_y}))
            test_accuracy  = np.mean(np.argmax(test_y, axis=1) ==
                                     sess.run(predict, feed_dict={X: test_X, y: test_y}))

            print("Epoch = %d, train accuracy = %.2f%%, test accuracy = %.2f%%"
                  % (epoch + 1, 100. * train_accuracy, 100. * test_accuracy))

if __name__ == '__main__':
    main()
```

As a sanity check, you might want to check if this (or your existing) model is running on CPU/GPU first. Once that is working, the first thing you need is a link pointing to the TPU. This can be obtained by adding the following at the top of the file, replacing `tpu_name` with the name of the TPU you created with `ctpu`. You probably want to refactor this to use the `TPU_NAME` environment variable, since I believe Google sets this for you if you do everything right, and it becomes easier to switch between TPUs this way. Note that this requires your compute instance and the TPU to be in the same region.

```python
from tensorflow.contrib import tpu
from tensorflow.contrib.cluster_resolver import TPUClusterResolver

# Get the TPU's location
tpu_cluster = TPUClusterResolver(
    tpu=['my_tpu']).get_master()
```

As of now, this is still doing nothing, so you need to pass this link to `tf.Session()` as the `target` argument (which is also the first). Another thing to be done is to initialize the TPU system when the session is created and clean up when you're done.

```python
with tf.Session(tpu_cluster) as sess:
    sess.run(tpu.initialize_system())

    # Do stuff here

    sess.run(tpu.shutdown_system())
```

And that's it! On running the model now, it should train on the TPU if it exists in the network. To verify it actually worked, you can make three checks:

* CPU usage when not on TPU should be significantly higher.
* Your cloud console should show a minor CPU usage for your TPU (0.9% in my case).
* It might run *slower* (if you're running the code above). Since this is just a toy problem, the network latency and other overhead of transferring information between the instance and the TPU probably becomes the bottleneck here.

# CrossShardOptimizer

However, doing the above will probably ensure you are not using all shards or the entire computing power of the TPU. Again, if you want to be foolproof about this, you should go for the Estimator API. Still, one thing that could possibly work (only speculation henceforth) is to use the `CrossShardOptimizer` wrapper around your optimizer. This should make your optimizer look something like
```python
updates = tf.contrib.tpu.CrossShardOptimizer(
            tf.train.GradientDescentOptimizer(0.01)).minimize(cost)
```

However, as soon as you do this, you should have a warning like
```
WARNING:tensorflow:CrossShardOptimizer should be used within a tpu_shard_context, but got unset number_of_shards. Assuming 1.
```

So we are using only one shard of eight. One really ugly way (which touches the internal APIs of TensorFlow) I found to fix *the warning* (emphasis on this since I still don't know if it really does use all shards after this), is to exlicitly set the number of shards as

```python
from tensorflow.contrib.tpu.python.tpu import tpu_function

# Add this somewhere at the top
tpu_function.get_tpu_context().set_number_of_shards(8)
```

I don't recommend this at all, but it *might* work. Do let me know if you actually do this and it does/doesn't

# Caveats
Note that since you're doing everything yourself, you need to make sure of a couple of things. Firstly, you cannot write to local storage from TPU, so you need to either comment out all writes or use a cloud bucket for this. Secondly, do a sanity check first, since code might not behave the same and a couple of changes here and there might be required for everything to work (again, mostly related to files).

# Conclusion
So finally, you have your TensorFlow model with the low level APIs running on TPU. Hopefully, we will have some official instruction on how to do this once TPUs are no longer in beta, since after all, these APIs are far from deprecated.

Happy Training!
