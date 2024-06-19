from flask import Flask, jsonify
import google.generativeai as genai
import json

app = Flask(__name__)

def register():
    name = input("Name: ")
    age = input("Age: ")
    grade_level = input("Grade Level: ")
    country = input("Country: ")
    return name, age, grade_level, country

def welcome():
    name, age, grade_level, country = register()

    print(f"\nWelcome {name}!")
    print(f"You are {age} years old.")
    print(f"Your grade level is {grade_level}.\n")
    print(f"Your country is {country}.\n")

    return name, age, grade_level, country

def get_subject():
    subject = input("Subject: ")
    return subject

# Configure the generative AI API key
genai.configure(api_key="AIzaSyCv4jeI3NtvwK28LBIp8OooWMmBPUx_sB0")

# Generation configuration shared by all models
generation_config = {
    "temperature": 1,
    "top_p": 0.95,
    "top_k": 64,
    "max_output_tokens": 58192,
    "response_mime_type": "application/json",
}

safety_settings = [
    {
        "category": "HARM_CATEGORY_HARASSMENT",
        "threshold": "BLOCK_MEDIUM_AND_ABOVE",
    },
    {
        "category": "HARM_CATEGORY_HATE_SPEECH",
        "threshold": "BLOCK_MEDIUM_AND_ABOVE",
    },
    {
        "category": "HARM_CATEGORY_SEXUALLY_EXPLICIT",
        "threshold": "BLOCK_MEDIUM_AND_ABOVE",
    },
    {
        "category": "HARM_CATEGORY_DANGEROUS_CONTENT",
        "threshold": "BLOCK_MEDIUM_AND_ABOVE",
    },
]

# Define multiple models for different tasks
topics_model = genai.GenerativeModel(
    model_name="gemini-1.5-pro",
    safety_settings=safety_settings,
    generation_config=generation_config,
    system_instruction="""You will create a list of 5 main topics for the given subject that helps the student learn on their own. 
        Make sure the topics cover fundamental and advanced concepts related to the subject and the grade level of the student."""
)

explanation_model = genai.GenerativeModel(
    model_name="gemini-1.5-pro",
    safety_settings=safety_settings,
    generation_config=generation_config,
    system_instruction="""You will provide detailed explanations for each topic. 
        Each explanation should be clear and concise, ensuring the student can understand the material on their own. 
        Include examples and relate them to real-world applications to make the content relatable.
        Add a dictionary of key terms and their meanings."""
)

exercise_quiz_model = genai.GenerativeModel(
    model_name="gemini-1.5-pro",
    safety_settings=safety_settings,
    generation_config=generation_config,
    system_instruction="""You will create exercises and quizzes for each topic, with solutions and varying difficulty levels. 
        Ensure the exercises help reinforce the concepts and the quizzes test the student's understanding. 
        Each difficulty level should have a minimum of 10 questions and answers, increasing in complexity."""
)

def reRun_model_if_needed(model, prompt, attempts=3):
    for attempt in range(attempts):
        try:
            response = model.start_chat(history=[]).send_message(prompt)
            # Attempt to parse the response text as JSON to verify it's valid
            json.loads(response.text)

            return response.text
        except (json.JSONDecodeError, Exception) as e:
            print(f"Attempt {attempt + 1} failed: {e}")
    return None
def generate_topics(name, age, grade_level, subject, country):
    prompt = f"""Create a list of 5 main topics for a student named {name} who is {age} years old, in grade {grade_level}, living in {country}, and wants to learn {subject}. The topics should cover fundamental and advanced concepts related to the subject."""
    # response = topics_model.start_chat(history=[]).send_message(prompt)
    # return response.text
    return reRun_model_if_needed(topics_model, prompt)

def generate_explanations(topics):
    prompt = f"""Based on the following topics, provide detailed explanations for each one. Ensure the explanations are clear and suitable for self-study. Include real-world examples and a dictionary of key terms and their meanings.\n\n{topics}"""
    # response = explanation_model.start_chat(history=[]).send_message(prompt)
    # return response.text
    return reRun_model_if_needed(explanation_model, prompt)

def generate_exercises_and_quizzes(explanations):
    prompt = f"""Based on the following explanations, create exercises and quizzes with solutions for each topic. Ensure the exercises help reinforce the concepts and the quizzes test the student's understanding. Each difficulty level should have a minimum of 10 questions and answers, increasing in complexity.\n\n{explanations}"""
    # response = exercise_quiz_model.start_chat(history=[]).send_message(prompt)
    # return response.text
    return reRun_model_if_needed(exercise_quiz_model, prompt)

@app.route('/generate-learning-materials', methods=['GET'])
def generate_learning_materials():
    name, age, grade_level, country = welcome()
    subject = get_subject()

    if not all([name, age, grade_level, subject, country]):
        return jsonify({"error": "Missing one or more required fields: name, age, grade_level, subject, country"}), 400

    topics = generate_topics(name, age, grade_level, subject, country)
    print("Topics:", topics)

    # explanations = generate_explanations(topics)
    # print("Explanations:", explanations)

    # exercises_and_quizzes = generate_exercises_and_quizzes(explanations)
    # print("Exercises and Quizzes:", exercises_and_quizzes)

    try:
        json_object = json.loads(topics)
        return jsonify(json_object)
    except json.JSONDecodeError:
        return jsonify({"error": "Failed to generate valid JSON response from AI model."}), 500

if __name__ == '__main__':
    app.run(debug=True)
