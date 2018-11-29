import random
import sys
import urllib.request as request

import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
import tensorflow as tf

from sklearn.model_selection import train_test_split

loss_plot = {5: [], 10: [], 20: []}  
weights1 = {5: None, 10: None, 20: None}  
weights2 = {5: None, 10: None, 20: None}  

def create_model(hidden_nodes, num_iters, xTrain, yTrain):

    # Reset the graph
    tf.reset_default_graph()

    # Placeholders for input and output data
    #X = tf.placeholder(shape=(120, 4), dtype=tf.float64, name='X')
    #y = tf.placeholder(shape=(120, 3), dtype=tf.float64, name='y')
    X = tf.placeholder(shape=xTrain.shape, dtype=tf.float64, name='X')
    Y = tf.placeholder(shape=yTrain.shape, dtype=tf.float64, name='Y')

    # Variables for two group of weights between the three layers of the network
    #W1 = tf.Variable(np.random.rand(4, hidden_nodes), dtype=tf.float64)
    #W2 = tf.Variable(np.random.rand(hidden_nodes, 3), dtype=tf.float64)
    W1 = tf.Variable(np.random.rand(xTrain.shape[1], hidden_nodes), dtype=tf.float64)
    W2 = tf.Variable(np.random.rand(hidden_nodes, yTrain.shape[1]), dtype=tf.float64)

    # Create the neural net graph
    A1 = tf.sigmoid(tf.matmul(X, W1))
    y_est = tf.sigmoid(tf.matmul(A1, W2))

    # Define a loss function
    deltas = tf.square(y_est - Y)
    loss = tf.reduce_sum(deltas)

    # Define a train operation to minimize the loss
    optimizer = tf.train.GradientDescentOptimizer(0.005)
    train = optimizer.minimize(loss)

    # Initialize variables and run session
    init = tf.global_variables_initializer()
    sess = tf.Session()
    sess.run(init)

    # Go through num_iters iterations
    for i in range(num_iters):
        sess.run(train, feed_dict={X: xTrain, Y: yTrain})
        loss_plot[hidden_nodes].append(sess.run(loss, feed_dict={X: xTrain.values, Y: yTrain.values}))
        weights1 = sess.run(W1)
        weights2 = sess.run(W2)

    print("loss (hidden nodes: %d, iterations: %d): %.2f" % (hidden_nodes, num_iters, loss_plot[hidden_nodes][-1]))
    sess.close()
    return weights1, weights2


def get_accuracy(weights1, weights2, xTest, yTest, num_hidden_nodes):
  X = tf.placeholder(shape=xTest.shape, dtype=tf.float64, name='X')  
  Y = tf.placeholder(shape=yTest.shape, dtype=tf.float64, name='Y')

  for hidden_nodes in num_hidden_nodes:

      # Forward propagation
      W1 = tf.Variable(weights1[hidden_nodes])
      W2 = tf.Variable(weights2[hidden_nodes])
      A1 = tf.sigmoid(tf.matmul(X, W1))
      y_est = tf.sigmoid(tf.matmul(A1, W2))

      # Calculate the predicted outputs
      init = tf.global_variables_initializer()
      with tf.Session() as sess:
          sess.run(init)
          y_est_np = sess.run(y_est, feed_dict={X: xTest, Y: yTest})

      # Calculate the prediction accuracy
      correct = [estimate.argmax(axis=0) == target.argmax(axis=0) 
                for estimate, target in zip(y_est_np, yTest.values)]
      accuracy = 100 * sum(correct) / len(correct)
      print('Network architecture 4-%d-3, accuracy: %.2f%%' % (hidden_nodes, accuracy))


def main(dataFile):
  # Read in data
  tags = pd.read_csv('tags.csv', header=None)
  names = np.insert(tags.values, 0, 'Style')
  names = np.append(names, 'ABV')
  names = np.append(names, 'IBU')
  data = pd.read_csv(dataFile, names=names, header=None, sep='\t')

  # Before we get our styles set up, we should probably simplify them to more general types
  styles = pd.read_csv('styles.csv', names=['Style'], header=None)
  for beer in data.Style:
    replaced = False
    for style in styles.Style:
      if style.lower() in beer.lower():
        data.replace(beer, style, inplace=True)
        replaced=True
        break
    if not replaced:
      data.replace(beer, 'beer', inplace=True)
        
  train, test = train_test_split(data, test_size=0.2)
  xTrain = train.drop('Style', axis=1)
  xTest = test.drop('Style', axis=1)

  # Encode target values into binary ('one-hot' style) representation
  yTrain = pd.get_dummies(train.Style)
  yTest = pd.get_dummies(test.Style)

  print('Training the Network')

  # Start the actual machine learning
  # Train it over 2000 iterations
  num_hidden_nodes = [5, 10, 20]  
  num_iters = 5000

  plt.figure(figsize=(12,8))  
  for hidden_nodes in num_hidden_nodes:  
    weights1[hidden_nodes], weights2[hidden_nodes] = create_model(hidden_nodes, num_iters, xTrain, yTrain)
    plt.plot(range(num_iters), loss_plot[hidden_nodes], label="nn: 4-%d-3" % hidden_nodes)

  plt.xlabel('Iteration', fontsize=12)  
  plt.ylabel('Loss', fontsize=12)  
  plt.legend(fontsize=12)  

  plt.savefig('LossGraph.png')

  # Check our results
  print('Checking accuracy')
  get_accuracy(weights1, weights2, xTest, yTest, num_hidden_nodes)


if __name__ == '__main__':
  main(sys.argv[1])
