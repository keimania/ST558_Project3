library(plumber)
library(tidyverse)
library(tidymodels)
library(ranger)

# 1. Data preparation and model training

# Read the data
diabetes <- read_csv("diabetes_binary_health_indicators_BRFSS2015.csv")

# Apply Data Cleaning and Factor Conversion
diabetes_clean <- diabetes |>
  mutate(
    Diabetes_binary = factor(Diabetes_binary, levels = c(0, 1), labels = c("No Diabetes", "Diabetes")),
    HighBP = factor(HighBP, levels = c(0, 1), labels = c("No High BP", "High BP")),
    HighChol = factor(HighChol, levels = c(0, 1), labels = c("No High Chol", "High Chol")),
    CholCheck = factor(CholCheck, levels = c(0, 1), labels = c("No Check", "Check in 5 yrs")),
    Smoker = factor(Smoker, levels = c(0, 1), labels = c("No", "Yes")),
    Stroke = factor(Stroke, levels = c(0, 1), labels = c("No", "Yes")),
    HeartDiseaseorAttack = factor(HeartDiseaseorAttack, levels = c(0, 1), labels = c("No", "Yes")),
    PhysActivity = factor(PhysActivity, levels = c(0, 1), labels = c("No", "Yes")),
    Fruits = factor(Fruits, levels = c(0, 1), labels = c("No", "Yes")),
    Veggies = factor(Veggies, levels = c(0, 1), labels = c("No", "Yes")),
    HvyAlcoholConsump = factor(HvyAlcoholConsump, levels = c(0, 1), labels = c("No", "Yes")),
    AnyHealthcare = factor(AnyHealthcare, levels = c(0, 1), labels = c("No", "Yes")),
    NoDocbcCost = factor(NoDocbcCost, levels = c(0, 1), labels = c("No", "Yes")),
    GenHlth = factor(GenHlth, levels = c(1, 2, 3, 4, 5), 
                     labels = c("Excellent", "Very Good", "Good", "Fair", "Poor")),
    DiffWalk = factor(DiffWalk, levels = c(0, 1), labels = c("No", "Yes")),
    Sex = factor(Sex, levels = c(0, 1), labels = c("Female", "Male")),
    Age = factor(Age), # Keeps levels 1-13
    Education = factor(Education),
    Income = factor(Income)
  )

# Define the Recipe
# Using the 8 predictors identified in modeling.qmd
rf_rec <- recipe(Diabetes_binary ~ BMI + HighBP + HighChol + GenHlth + Age + PhysActivity + DiffWalk + HeartDiseaseorAttack, data = diabetes_clean)

# Random Forest

rf_spec <- rand_forest(
  mtry = 2,       # The parameter from "select_best(rf_fits, metric = "mn_log_loss")"
  min_n = 40,      # The parameter from "select_best(rf_fits, metric = "mn_log_loss")"
  trees = 100
) |>
  set_engine("ranger") |>
  set_mode("classification")

# Create Workflow and Fit to the entire dataset
rf_wf <- workflow() |>
  add_recipe(rf_rec) |>
  add_model(rf_spec)

final_model_fit <- fit(rf_wf, data = diabetes_clean)

# 2. API endpoints

#* @apiTitle Diabetes Prediction API
#* @apiDescription An API to predict diabetes risk using a Random Forest model trained on BRFSS 2015 data.

#* An info endpoint : Return Author Name and GitHub Page
#* @get /info
function() {
  list(
    name = "Jamin Goo",
    github_page = "https://github.com/keimania/ST558_Project3/"
  )
}

#* A confusion endpoint : Return Confusion Matrix Plot
#* @serializer png
#* @get /confusion
function() {
  # Get predictions on the full dataset
  preds <- predict(final_model_fit, new_data = diabetes_clean) |>
    bind_cols(diabetes_clean |> select(Diabetes_binary))
  
  # Create plot
  p <- conf_mat(preds, truth = Diabetes_binary, estimate = .pred_class) |>
    autoplot(type = "heatmap") +
    labs(title = "Confusion Matrix")
  
  print(p)
}

#* Predict Diabetes Status
#* @param BMI Body Mass Index (Numeric, e.g., 28)
#* @param HighBP High Blood Pressure (0 = No, 1 = Yes)
#* @param HighChol High Cholesterol (0 = No, 1 = Yes)
#* @param GenHlth General Health (1=Excellent to 5=Poor)
#* @param Age Age Category (1 to 13)
#* @param PhysActivity Physical Activity (0 = No, 1 = Yes)
#* @param DiffWalk Difficulty Walking (0 = No, 1 = Yes)
#* @param HeartDiseaseorAttack Heart Disease or Attack (0 = No, 1 = Yes)
#* @post /pred
function(BMI = 28, HighBP = 0, HighChol = 0, GenHlth = 3, Age = 9, PhysActivity = 1, DiffWalk = 0, HeartDiseaseorAttack = 0) {
  
  # Create a data frame from inputs
  input_data <- tibble(
    BMI = as.numeric(BMI),
    HighBP = factor(HighBP, levels = c(0, 1), labels = c("No High BP", "High BP")),
    HighChol = factor(HighChol, levels = c(0, 1), labels = c("No High Chol", "High Chol")),
    GenHlth = factor(GenHlth, levels = c(1, 2, 3, 4, 5), labels = c("Excellent", "Very Good", "Good", "Fair", "Poor")),
    Age = factor(Age, levels = 1:13), 
    PhysActivity = factor(PhysActivity, levels = c(0, 1), labels = c("No", "Yes")),
    DiffWalk = factor(DiffWalk, levels = c(0, 1), labels = c("No", "Yes")),
    HeartDiseaseorAttack = factor(HeartDiseaseorAttack, levels = c(0, 1), labels = c("No", "Yes"))
  )
  
  # Make Prediction
  pred_class <- predict(final_model_fit, new_data = input_data, type = "class")
  pred_prob  <- predict(final_model_fit, new_data = input_data, type = "prob")
  
  # Return result list
  list(
    prediction = pred_class$.pred_class,
    probability_diabetes = pred_prob$.pred_Diabetes
  )
}


# 3. example function calls

# 1) /info Endpoint
# Request: GET
# Purpose: Retrieve author name and GitHub page URL.
# curl -X GET "http://localhost:23464/info"

# 2) /confusion Endpoint
# Request: GET
# Purpose: Generate and download the confusion matrix plot as a PNG file named 'confusion.png'.
# curl -X GET "http://localhost:23464/confusion" --output confusion.png

# 3) /pred Endpoint
# Request: POST
# Purpose: Predict diabetes status based on input health indicators.
# Parameters passed in URL query string: BMI=30, HighBP=1, HighChol=1, GenHlth=4, Age=10,PhysActivity=0, DiffWalk=1, HeartDiseaseorAttack=1
# curl -X POST "http://localhost:23464/pred?BMI=30&HighBP=1&HighChol=1&GenHlth=4&Age=10&PhysActivity=0&DiffWalk=1&HeartDiseaseorAttack=1"