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

model = genai.GenerativeModel(
  model_name="gemini-1.5-pro",
  safety_settings=safety_settings,
  generation_config=generation_config,
  system_instruction="""You will act as a Professional Teacher. 
            You will be given the student's profile, including their current grade level, country and the subject they want to learn. Do not ask them their learning goals.
            
            \n\nYou will create learning materials and lessons that reflect the student's profile specially in their grade level and the subject they want to learn. 
            Make the learning engaging and relatable, fostering a deeper connection with the subject matter and aligning with what other teachers teach at the school.
            
            \n\nRecommend 3 topics related to the subject. 

            \n\nFor each topic:

                \n\nProvide a detailed explanation. Explain the example with minimum of 5 sentences in each explanation.
                \nProvide also a Dictionary of Words with meaning.
                \nSeparate the topic title and the description in the JSON output
                \nInclude 3 detailed lesson examples with explanations to help the student understand the topic.
                \nRecommend personalized exercises to address the student's learning gaps. The exercises should be related to the lesson given.
                \nProvide quizzes with solutions for each topic, with 3 difficulty levels (easy, medium, hard) in each topic. Each difficulty level should have a minimum of 10 questions and answers, increasing in difficulty.
                \nNote: Explain each topic like your explaining to a child below 18 years old.
            \n\nUse this JSON output pattern:
            \n{\n  \"learning_materials\": 
                        [{\n      
                            \"topics\": \"\" \n, 
                                [{\n          
                                    \"description\": \"\",\n          
                                    \"examples\": 
                                        [{\n              
                                            \"example\": \"\",\n              
                                            \"explanation\": \"\"\n 
                                        }],
                            \n      \"quiz\": 
                                        [{\n              
                                            \"difficulty\": \"\",\n              
                                            \"questions\": [],\n              
                                            \"answers\": []
                                        }]\n        
                                }]\n    
                        }]\n
                }\n"""
    )

@app.route('/generate-learning-materials', methods=['GET'])
def generate_learning_materials():
    name, age, grade_level, country = welcome()
    subject = get_subject()

    if not all([name, age, grade_level, subject, country]):
        return jsonify({"error": "Missing one or more required fields: name, age, grade_level, subject"}), 400

    prompt = f"""Student {name} (age {age}, grade {grade_level}) wants to learn {subject}. You live in {country}."""

    for attempt in range(3):

        chat_session = model.start_chat(
            history=[]
        )
        response = chat_session.send_message(prompt)
        print(response.text)

        try:
            # Attempt to parse the response text as JSON
            json_object = json.loads(response.text)
            return jsonify(json_object)
        except json.JSONDecodeError:
            # Handle the case where the response is not valid JSON
            print(f"Attempt {attempt + 1} failed: Invalid JSON response")

    # If all attempts fail, return an error response
    return jsonify({"error": "Failed to generate valid JSON response from AI model after multiple attempts."}), 500


if __name__ == '__main__':
    app.run(debug=True)
