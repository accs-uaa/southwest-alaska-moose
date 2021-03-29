# Import packages
import numpy as np
import pandas as pd
import os
import seaborn as sns
import matplotlib.pyplot as plot

# Import modules for model selection, cross validation, logistic regression, and performance from Scikit Learn
from sklearn.linear_model import LogisticRegression
from sklearn.utils import shuffle
from sklearn.feature_selection import RFECV
from sklearn.model_selection import cross_val_predict
from sklearn.model_selection import cross_val_score
from sklearn.model_selection import train_test_split
from sklearn.model_selection import StratifiedKFold
from sklearn.metrics import accuracy_score
from sklearn.metrics import confusion_matrix
from sklearn.metrics import roc_curve
from sklearn.metrics import auc
from sklearn.metrics import roc_auc_score
from sklearn.model_selection import GridSearchCV
from sklearn.preprocessing import LabelEncoder

# Import joblib
import joblib

# Import timing packages
import time
import datetime

# Set root directory
drive = 'C:\\'
root_folder = 'Users\\adroghini\\Documents\\GitHub\\southwest-alaska-moose'
output_folder = os.path.join(drive, root_folder,
                           'output\\modelResults')

# Create a plots folder if it does not exist
plots_folder = os.path.join(output_folder, "plots")
if not os.path.exists(plots_folder):
    os.makedirs(plots_folder)

# Define input path
input_file = os.path.join(drive, root_folder, 'pipeline\\paths\\allPaths_forModel_meanCovariates.csv')

# Define output test data
output_csv = os.path.join(output_folder, 'prediction.csv')
# Define output model files
output_classifier = os.path.join(output_folder, 'classifier.joblib')
# Define output threshold file
threshold_file = os.path.join(output_folder, 'threshold.txt')
# Define output correlation plot
variable_correlation = os.path.join(plots_folder, "variable_correlation.png")
# Define output bayesian optimization convergence plots
convergence_classifier = os.path.join(plots_folder, "convergence_classifier.png")

# Define variables
predictor_all = ['elevation_mean', 'roughness_mean', 'forest_edge_mean','tundra_edge_mean','alnus_mean','betshr_mean','dectre_mean','erivag_mean','picgla_mean','picmar_mean','salshr_mean','wetsed_mean']
response = ['response']
retain_variables = ['mooseYear_id','fullPath_id','calfStatus']
all_variables = retain_variables + predictor_all + response
iteration = ['iteration']
absence = ['absence']
presence = ['presence']
prediction = ['prediction']
output_variables = all_variables + absence + presence + prediction + iteration

# Define a function to calculate performance metrics based on a specified threshold value
def testPresenceThreshold(predict_probability, threshold, y_test):
    # Create an empty array of zeroes that matches the length of the probability predictions
    predict_thresholded = np.zeros(predict_probability.shape)
    # Set values for all probabilities greater than or equal to the threshold equal to 1
    predict_thresholded[predict_probability >= threshold] = 1
    # Determine error rates
    confusion_test = confusion_matrix(y_test, predict_thresholded)
    true_negative = confusion_test[0,0]
    false_negative = confusion_test[1,0]
    true_positive = confusion_test[1,1]
    false_positive = confusion_test[0,1]
    # Calculate sensitivity and specificity
    sensitivity = true_positive / (true_positive + false_negative)
    specificity = true_negative / (true_negative + false_positive)
    # Calculate AUC score
    auc = roc_auc_score(y_test, predict_probability)
    # Calculate overall accuracy
    accuracy = (true_negative + true_positive) / (true_negative + false_positive + false_negative + true_positive)
    # Return the thresholded probabilities and the performance metrics
    return (sensitivity, specificity, auc, accuracy)

# Create a function to determine a presence threshold
def determineOptimalThreshold(predict_probability, y_test):
    # Iterate through numbers between 0 and 1000 to output a list of sensitivity and specificity values per threshold number
    i = 1
    sensitivity_list = []
    specificity_list = []
    while i < 1001:
        threshold = i/1000
        sensitivity, specificity, auc, accuracy = testPresenceThreshold(predict_probability, threshold, y_test)
        sensitivity_list.append(sensitivity)
        specificity_list.append(specificity)
        i = i + 1
    # Calculate a list of absolute value difference between sensitivity and specificity and find the optimal threshold
    difference_list = [np.absolute(a - b) for a, b in zip(sensitivity_list, specificity_list)]
    value, threshold = min((value, threshold) for (threshold, value) in enumerate(difference_list))
    threshold = threshold/1000
    # Calculate the performance of the optimal threshold
    sensitivity, specificity, auc, accuracy = testPresenceThreshold(predict_probability, threshold, y_test)
    # Return the optimal threshold and the performance metrics of the optimal threshold
    return threshold, sensitivity, specificity, auc, accuracy

#### Export Results Function

# Define a function to plot Pearson correlation of predictor variables
def plotVariableCorrelation(X_train, outFile):
    # Calculate Pearson correlation coefficient between the predictor variables, where -1 is perfect negative correlation and 1 is perfect positive correlation
    correlation = X_train.astype('float64').corr()
    # Generate a mask for the upper triangle of plot
    mask = np.zeros_like(correlation, dtype=np.bool)
    mask[np.triu_indices_from(mask)] = True
    # Set up the matplotlib figure
    f, ax = plot.subplots(figsize=(20, 18))
    # Generate a custom diverging colormap
    cmap = sns.diverging_palette(220, 10, as_cmap=True)
    # Draw the heatmap with the mask and correct aspect ratio
    correlation_plot = sns.heatmap(correlation, mask=mask, cmap=cmap, vmax=.3, center=0, square=True, linewidths=.5, cbar_kws={'shrink': .5})
    correlation_figure = correlation_plot.get_figure()
    correlation_figure.savefig(outFile, bbox_inches='tight', dpi=300)
    # Clear plot workspace
    plot.clf()
    plot.close()

#### Load Data

# Load dataset
moosePaths = pd.read_csv(input_file)

# Split dataset into paths with calves and paths without calves
input_data = moosePaths[moosePaths['calfStatus']==1]
# paths = moosePaths[moosePaths['calfStatus']==0]

# Convert values to floats
input_data[predictor_all] = input_data[predictor_all].astype(float)

# Convert values to integers
input_data[response] = input_data[response].astype('int32')

# Shuffle data
input_data = shuffle(input_data, random_state=21)

# Split the X and y data for classification
X_classify = input_data[predictor_all].astype(float)
y_classify = input_data[response[0]].astype('int32')

# Set initial plot sizefig_size = plot.rcParams["figure.figsize"]
fig_size = plot.rcParams["figure.figsize"]
fig_size[0] = 8
fig_size[1] = 6
plot.rcParams["figure.figsize"] = fig_size
plot.style.use('grayscale')

#### Train and Test Iterations
# Define 10-fold cross validation split methods
outer_cv_splits = StratifiedKFold(n_splits = 5, shuffle = True, random_state = 314)
inner_cv_splits = StratifiedKFold(n_splits = 5, shuffle = True, random_state = None)

# Create empty lists to store threshold and performance metrics
threshold_list = []
# Create an empty data frame to store the outer cross validation splits
outer_train = pd.DataFrame(columns = all_variables + iteration)
outer_test = pd.DataFrame(columns = all_variables + iteration)

# Create an empty data frame to store the outer test results
outer_results = pd.DataFrame(columns = output_variables)

# Create outer cross validation splits for cover data
count = 1
for train_index, test_index in outer_cv_splits.split(input_data, input_data[response[0]]):
    # Split the data into train and test partitions
    train = input_data.iloc[train_index]
    test = input_data.iloc[test_index]
    # Insert iteration to train
    train[iteration[0]] = count
    # Insert iteration to test
    test[iteration[0]] = count
    # Append to data frames
    outer_train = outer_train.append(train, ignore_index = True, sort = True)
    outer_test = outer_test.append(test, ignore_index = True, sort = True)
    # Increase counter
    count += 1

print(outer_train['iteration'])
print(outer_test['iteration'])

# Reset indices
outer_train = outer_train.reset_index()
outer_test = outer_test.reset_index()

#### MODEL TRAIN AND TEST ITERATIONS WITH HYPERPARAMETER AND THRESHOLD OPTIMIZATION IN NESTED CROSS-VALIDATION
####____________________________________________________

# Iterate through outer cross validation splits
i = 1
while i < 6:

    #### CONDUCT MODEL TRAIN
    ####____________________________________________________

    # Partition the outer train split by iteration number
    print(f'Conducting outer cross-validation iteration {i} of 5...')
    train_iteration = outer_train[outer_train[iteration[0]] == i]

    # Identify X and y train splits for the classifier
    X_train_classify = train_iteration[predictor_all].astype(float)
    le = LabelEncoder()
    le.fit(train_iteration[response[0]])
    list(le.classes_)
    y_train_classify = le.transform(train_iteration[response[0]])
#    y_train_classify = train_iteration[response[0]].astype('int32')

    # Set classifier convergence plot output
    convergence_classifier_partial = os.path.splitext(convergence_classifier)[0] + str(i) + '.png'

    # Conduct Bayesian Optimization on the classifier train dataset using inner cross validation
    print('\tOptimizing classifier hyperparameters...')
    iteration_start = time.time()
    # Define model parameters
    parameters = {'penalty': ['l1'], 'C': [.001, 10], 'solver': ['liblinear']}
    # Run test classifier
    classifier = LogisticRegression(penalty = 'l1', C = 0.01, solver='liblinear')
    classifier.fit(X_train_classify, y_train_classify)
    print('SUCCESS!')
    # Create a classifier
    skf = StratifiedKFold(n_splits=2)
    splits = skf.split(X_train_classify, y_train_classify)
    print('SUCCESS!!')
    grid_classifier = GridSearchCV(LogisticRegression(), param_grid = parameters, scoring = 'roc_auc', n_jobs = 2, cv = splits)
    # Fit Classifier through Grid Search
    print(y_train_classify)
    grid_classifier.fit(X_train_classify, y_train_classify)
    print('SUCCESS!!!')
    # Select best parameters
    best_parameters = grid_classifier.best_params_
    print(best_parameters)
    iteration_end = time.time()
    iteration_elapsed = int(iteration_end - iteration_start)
    iteration_success_time = datetime.datetime.now()
    print(
        f'\tCompleted at {iteration_success_time.strftime("%Y-%m-%d %H:%M")} (Elapsed time: {datetime.timedelta(seconds=iteration_elapsed)})')
    print('\t----------')

    # Predict each training data row in inner cross validation
    print('\tOptimizing classification threshold...')
    iteration_start = time.time()

    # Create an empty data frame to store the inner cross validation splits
    inner_train = pd.DataFrame(columns=all_variables + iteration + ['inner'])
    inner_test = pd.DataFrame(columns=all_variables + iteration + ['inner'])

    # Create an empty data frame to store the inner test results
    inner_results = pd.DataFrame(
        columns=all_variables + absence + presence + prediction + iteration + ['inner'])

    # Create inner cross validation splits
    count = 1
    for train_index, test_index in inner_cv_splits.split(train_iteration, train_iteration[response[0]]):
        # Split the data into train and test partitions
        train = train_iteration.iloc[train_index]
        test = train_iteration.iloc[test_index]
        # Insert iteration to train
        train['inner'] = count
        # Insert iteration to test
        test['inner'] = count
        # Append to data frames
        inner_train = inner_train.append(train, ignore_index=True, sort=True)
        inner_test = inner_test.append(test, ignore_index=True, sort=True)
        # Increase counter
        count += 1

    # Iterate through inner cross validation splits
    n = 1
    while n < 6:
        inner_train_iteration = inner_train[inner_train['inner'] == n]
        inner_test_iteration = inner_test[inner_test['inner'] == n]

        # Identify X and y inner train and test splits
        X_train_inner = inner_train_iteration[predictor_all].astype(float)
        y_train_inner = inner_train_iteration[response[0]].astype('int32')
        X_test_inner = inner_test_iteration[predictor_all].astype(float)
        y_test_inner = inner_test_iteration[response[0]].astype('int32')

        # Train classifier on the inner train data
        classifier = LogisticRegression(best_parameters)
        classifier.fit(X_train_inner, y_train_inner)

        # Predict probabilities for inner test data
        probability_inner = classifier.predict_proba(X_test_inner)
        # Concatenate predicted values to test data frame
        inner_test_iteration['absence'] = probability_inner[:, 0]
        inner_test_iteration['presence'] = probability_inner[:, 1]

        # Add iteration number to inner test iteration
        inner_test_iteration['inner'] = n

        # Add the test results to output data frame
        inner_results = inner_results.append(inner_test_iteration, ignore_index=True, sort=True)

        # Increase n value
        n += 1

    # Calculate the optimal threshold and performance of the presence-absence classification
    inner_results[response[0]] = inner_results[response[0]].astype('int32')
    threshold, sensitivity, specificity, auc, accuracy = determineOptimalThreshold(inner_results[presence[0]],
                                                                                   inner_results[response[0]])
    threshold_list.append(threshold)
    iteration_end = time.time()
    iteration_elapsed = int(iteration_end - iteration_start)
    iteration_success_time = datetime.datetime.now()
    print(
        f'\tCompleted at {iteration_success_time.strftime("%Y-%m-%d %H:%M")} (Elapsed time: {datetime.timedelta(seconds=iteration_elapsed)})')
    print('\t----------')

    # Train classifier
    print('\tTraining classifier...')
    iteration_start = time.time()
    classifier.fit(X_train_classify, y_train_classify)
    iteration_end = time.time()
    iteration_elapsed = int(iteration_end - iteration_start)
    iteration_success_time = datetime.datetime.now()
    print(
        f'\tCompleted at {iteration_success_time.strftime("%Y-%m-%d %H:%M")} (Elapsed time: {datetime.timedelta(seconds=iteration_elapsed)})')
    print('\t----------')

    #### CONDUCT MODEL TEST
    ####____________________________________________________

    # Partition the outer test split by iteration number
    print('\tPredicting outer cross-validation test data...')
    iteration_start = time.time()
    test_iteration = outer_test[outer_test[iteration[0]] == i]

    # Identify X test split
    X_test = test_iteration[predictor_all]

    # Use the classifier to predict class probabilities
    probability_prediction = classifier.predict_proba(X_test)
    # Concatenate predicted values to test data frame
    test_iteration['absence'] = probability_prediction[:, 0]
    test_iteration['presence'] = probability_prediction[:, 1]

    # Convert probability to presence-absence
    presence_zeros = np.zeros(test_iteration[presence[0]].shape)
    presence_zeros[test_iteration[presence[0]] >= threshold] = 1
    # Concatenate prediction values to test data frame
    test_iteration['prediction'] = presence_zeros

    # Add iteration number to test iteration
    test_iteration[iteration[0]] = i

    # Add the test results to output data frame
    outer_results = outer_results.append(test_iteration, ignore_index=True, sort=True)
    iteration_end = time.time()
    iteration_elapsed = int(iteration_end - iteration_start)
    iteration_success_time = datetime.datetime.now()
    print(
        f'\tCompleted at {iteration_success_time.strftime("%Y-%m-%d %H:%M")} (Elapsed time: {datetime.timedelta(seconds=iteration_elapsed)})')
    print('\t----------')

    # Increase iteration number
    i += 1

print(len(outer_results))

# Partition output results to presence-absence observed and predicted
y_classify_observed = outer_results[response[0]].astype('int32')
y_classify_predicted = outer_results[response[0]].astype('int32')
y_classify_probability = outer_results[presence[0]]

# Determine error rates
confusion_test = confusion_matrix(y_classify_observed, y_classify_predicted)
true_negative = confusion_test[0,0]
false_negative = confusion_test[1,0]
true_positive = confusion_test[1,1]
false_positive = confusion_test[0,1]
# Calculate sensitivity and specificity
sensitivity = true_positive / (true_positive + false_negative)
specificity = true_negative / (true_negative + false_positive)
# Calculate AUC score
auc = roc_auc_score(y_classify_observed, y_classify_probability)
# Calculate overall accuracy
accuracy = (true_negative + true_positive) / (true_negative + false_positive + false_negative + true_positive)

# Print performance results
print(f'Final AUC = {auc}')
print(f'Final Accuracy = {accuracy}')