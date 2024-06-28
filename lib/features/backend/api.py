from flask import Flask, jsonify, request
import google.generativeai as genai
import json

app = Flask(__name__)

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

quiz_model = genai.GenerativeModel(
    model_name="gemini-1.5-pro",
    safety_settings=safety_settings,
    generation_config=generation_config,
    system_instruction="""You will create quizzes for each topic, with solutions and varying difficulty levels. 
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
    prompt = (
        f"Create a list of 5 main topics for a student named {name} who is {age} years old, "
        f"in grade {grade_level}, living in {country}, and wants to learn {subject}. "
        "The topics should cover fundamental concepts related to the subject. "
        "\nIt should be stored in with this json format: "
        "{\n"
        "    \"topics\": [\"topic1\", \"topic2\", \"topic3\", \"topic4\", \"topic5\"]\n"
        "}"
    )

    return reRun_model_if_needed(topics_model, prompt)

def generate_explanations(topic):
    prompt = f"""
    Based on the following topic, provide a comprehensive course module.
    Ensure the module is detailed and suitable for self-study, including multiple lessons with thorough explanations.
    
    Create a self-study course module on the topic "{topic}" with three detailed lessons. 
    Each lesson should include:
    - A detailed explanation or content (explain to a 10 year old child) that is not less than 5 sentences.
    - Four real-world examples
    - A summary (make it a paragraph form that a child can understand)
    - Ten practice questions
    - Key terms and definitions

    Use LaTeX formatting enclosed in $...$ for inline math and $$...$$ for display math for any mathematical expressions.

    Topic: {topic}

    The output should be in the following JSON format:
    {{
        "module": {{
            "title": "Title of Module",
            "lessons": [
                {{
                    "title": "Title of Lesson 1",
                    "content": "detailed explanation here",
                    "examples": [
                        {{"title": "Title of Example 1", "content": "example1", "explanation": "example1 description"}},
                        {{"title": "Title of Example 2", "content": "example2", "explanation": "example2 description"}}
                    ],
                    "summary": "summary of the lesson",
                    "practice_questions": [
                        {{"question": "Question 1", "answer": "answer1"}},
                        {{"question": "Question 2", "answer": "answer2"}}
                    ],
                    "key_terms": {{
                        "term1": "definition1",
                        "term2": "definition2"
                    }}
                }},
                {{
                    "title": "Title of Lesson 2",
                    "content": "detailed explanation here",
                    "examples": [
                        {{"title": "Title of Example 1", "content": "example1", "explanation": "example1 description"}},
                        {{"title": "Title of Example 2", "content": "example2", "explanation": "example2 description"}}
                    ],
                    "summary": "summary of the lesson",
                    "practice_questions": [
                        {{"question": "Question 1", "answer": "answer1"}},
                        {{"question": "Question 2", "answer": "answer2"}}
                    ],
                    "key_terms": {{
                        "term1": "definition1",
                        "term2": "definition2"
                    }}
                }}
                ...
            ]
        }}
    }}
    """

    return reRun_model_if_needed(explanation_model, prompt)

def generate_quiz(explanations_json):
    prompt = f"""
    Based on the following detailed explanations of the topics, create quizzes with multiple choice questions and solutions for each lesson. Ensure the quizzes reinforce the concepts and test the student's understanding. Each lesson should have at least 10 questions.

    Lesson Topic Explanations: {explanations_json}

    The output should be in the following JSON format:
    {{
        "quizzes": [
            {{
                "lesson_title": "Title of Lesson 1",
                "questions": [
                    {{"question": "Question 1", "choices": ["Option 1", "Option 2", "Option 3", "Option 4"], "answer": "Correct Answer", "explanation": "Explanation for the correct answer"}},
                    {{"question": "Question 2", "choices": ["Option 1", "Option 2", "Option 3", "Option 4"], "answer": "Correct Answer", "explanation": "Explanation for the correct answer"}}
                ]
            }},
            {{
                "lesson_title": "Title of Lesson 2",
                "questions": [
                    {{"question": "Question 1", "choices": ["Option 1", "Option 2", "Option 3", "Option 4"], "answer": "Correct Answer", "explanation": "Explanation for the correct answer"}},
                    {{"question": "Question 2", "choices": ["Option 1", "Option 2", "Option 3", "Option 4"], "answer": "Correct Answer", "explanation": "Explanation for the correct answer"}}
                ]
            }}
            ...
        ]
    }}
    """
    return reRun_model_if_needed(quiz_model, prompt)



@app.route('/generate-topics', methods=['GET'])
def generate_topics_route():
    name = request.args.get('name')
    age = request.args.get('age')
    grade_level = request.args.get('grade')
    country = request.args.get('country')
    subject = request.args.get('subject')

    if not all([name, age, grade_level, subject, country]):
        return jsonify({"error": "Missing one or more required fields: name, age, grade_level, subject, country"}), 400

    topics = generate_topics(name, age, grade_level, subject, country)
    print("Topics:", topics)

    try:
        json_object = json.loads(topics)
        return jsonify(json_object)
    except json.JSONDecodeError:
        return jsonify({"error": "Failed to generate valid JSON response from AI model."}), 500

@app.route('/generate-topics-lesson', methods=['GET'])
def generate_topics_lesson_route():
    topic = request.args.get('topic')

    if not all([topic]):
        return jsonify({"error": "Missing one or more required fields: topics"}), 400
    
    lesson_topic = generate_explanations(topic)
    print("Lesson Topics:", lesson_topic)

    try:
        json_object = json.loads(lesson_topic)
        return jsonify(json_object)
    except json.JSONDecodeError:
        return jsonify({"error": "Failed to generate valid JSON response from AI model."}), 500


@app.route('/generate-quiz', methods=['POST'])
def generate_quiz_route():
    explanations_json = request.json.get('explanations')

    if not explanations_json:
        return jsonify({"error": "Missing explanations JSON"}), 400

    quiz = generate_quiz(explanations_json)
    print("Quiz:", quiz)

    try:
        json_object = json.loads(quiz)
        return jsonify(json_object)
    except json.JSONDecodeError:
        return jsonify({"error": "Failed to generate valid JSON response from AI model."}), 500


if __name__ == '__main__':
    app.run(debug=True)
