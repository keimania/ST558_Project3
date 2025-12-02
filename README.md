# Diabetes Prediction Project

**Author:** Jamin Goo\
**Course:** ST 558 - Data Science for Statisticians

## 1. Project Overview

This project aims to analyze health indicators from the **BRFSS 2015** dataset to predict whether an individual has diabetes. The analysis involves exploratory data analysis (EDA), training machine learning models (Classification Tree and Random Forest), and deploying the best-performing model as a REST API using `plumber` and Docker.

The primary goal is to provide an accessible API that can predict diabetes risk based on key health factors such as BMI, High Blood Pressure, Cholesterol, Age, and General Health status.

## 2. Dataset

The dataset used is the **Diabetes Health Indicators Dataset** (`diabetes_binary_health_indicators_BRFSS2015.csv`). It contains **253,680** survey responses with **21** variables. The target variable is `Diabetes_binary` (0 = No Diabetes, 1 = Diabetes).

## 3. Repository Structure

-   **`EDA.qmd`**: A Quarto document performing Exploratory Data Analysis. It cleans the data, checks for missing values, and visualizes relationships between predictors and diabetes status.
    -   *Output:* Generates `index.html` (the landing page).
-   **`Modeling.qmd`**: A Quarto document that trains, tunes, and compares a Classification Tree and a Random Forest model. It selects the best model based on **Log Loss** and prepares the data for the API.
    -   *Output:* Generates `Modeling.html`.
-   **`API.R`**: An R script using the `plumber` package to serve the best-performing model (Random Forest) as an API.
-   **`Dockerfile`**: A configuration file to containerize the API environment, ensuring reproducibility across different systems.
-   **`diabetes_binary_health_indicators_BRFSS2015.csv`**: The raw dataset used for analysis and model training.

## 4. How to View the Analysis

This project is hosted on GitHub Pages. You can view the rendered analysis reports here:

-   [**Exploratory Data Analysis (Landing Page)**](https://keimania.github.io/ST558_Project3/)
-   [**Modeling Report**](https://keimania.github.io/ST558_Project3/Modeling.html)

## 5. How to Run the API (Docker)

You can run the predictive model API locally using Docker. Follow these steps:

### 5.1. Build the Docker Image

Navigate to the project directory in your terminal and run:

``` bash
docker build -t diabetes-api .
```

### 5.2. Run the Container

Run the container, mapping port 8000 of the container to port 8000 on your host machine:

``` bash
docker run --rm -p 8000:8000 diabetes-api
```

Once running, the API will be accessible at http://localhost:8000.

## 6. API Endpoints

The API provides three endpoints:

### 6.1. /info (GET)

Returns the author's name and a link to the GitHub Pages site.

**Example Call:**

``` bash
curl -X GET "http://localhost:8000/info"
```

### 6.2. /confusion (GET)

Returns a PNG image of the confusion matrix for the model evaluated on the full dataset.

**Example Call:**

``` bash
curl -X GET "http://localhost:8000/confusion" --output confusion.png
```

### 6.3. /pred (POST)

Predicts the probability and class of diabetes for a given set of health indicators.

-   **Parameters:** BMI (numeric), HighBP, HighChol, GenHlth, Age, PhysActivity, DiffWalk, HeartDiseaseorAttack (all numeric codes representing categories).
-   **Defaults:** If parameters are omitted, the API uses the mean (for numeric) or mode (for categorical) of the dataset.

**Example Call (Default Values):**

``` bash
curl -X POST "http://localhost:8000/pred"
```

**Example Call (Custom Values):**

``` bash
curl -X POST "http://localhost:8000/pred?BMI=30&HighBP=1&HighChol=1&GenHlth=4&Age=10&PhysActivity=0&DiffWalk=1&HeartDiseaseorAttack=1"
```
