import io
import socket
from PIL import Image
import numpy as np
import tensorflow as tf
from fastapi import FastAPI, Request

# Load and prepare the TFLite model
def load_compact_model():
    model_path = "/Users/yuvalsavaryegolandesman/Desktop/deploy_model.tflite"
    interpreter = tf.lite.Interpreter(model_path=model_path)
    interpreter.allocate_tensors()  # Set up input and output tensors
    return interpreter  # Return ready-to-use model

# Load image from bytes and preprocess for model input
def preprocess_image(image_bytes):
    img = Image.open(io.BytesIO(image_bytes)).convert("RGB").resize((224, 224))  # Decode, RGB, resize
    img_array = np.array(img).astype(np.float32) / 255.0  # Normalize pixel values
    img_array = np.expand_dims(img_array, axis=0)  # Add batch dimension
    return img_array

# Run inference on image and return predicted label
def image_to_label(image_bytes):
  
    breed_labels = [
    'Afghan Hound',
    'African Hunting Dog',
    'Airedale',
    'American Staffordshire Terrier',
    'Appenzeller',
    'Australian Terrier',
    'Bedlington Terrier',
    'Bernese Mountain Dog',
    'Blenheim Spaniel',
    'Border Collie',
    'Border Terrier',
    'Boston Bull',
    'Bouvier Des Flandres',
    'Brabancon Griffon',
    'Brittany Spaniel',
    'Cardigan',
    'Chesapeake Bay Retriever',
    'Chihuahua',
    'Dandie Dinmont',
    'Doberman',
    'English Foxhound',
    'English Setter',
    'English Springer',
    'Entlebucher',
    'Eskimo Dog',
    'French Bulldog',
    'German Shepherd',
    'German Short Haired Pointer',
    'Gordon Setter',
    'Great Dane',
    'Great Pyrenees',
    'Greater Swiss Mountain Dog',
    'Ibizan Hound',
    'Irish Setter',
    'Irish Terrier',
    'Irish Water Spaniel',
    'Irish Wolfhound',
    'Italian Greyhound',
    'Japanese Spaniel',
    'Kerry Blue Terrier',
    'Labrador Retriever',
    'Lakeland Terrier',
    'Leonberg',
    'Lhasa',
    'Maltese Dog',
    'Mexican Hairless',
    'Newfoundland',
    'Norfolk Terrier',
    'Norwegian Elkhound',
    'Norwich Terrier',
    'Old English Sheepdog',
    'Pekinese',
    'Pembroke',
    'Pomeranian',
    'Rhodesian Ridgeback',
    'Rottweiler',
    'Saint Bernard',
    'Saluki',
    'Samoyed',
    'Scotch Terrier',
    'Scottish Deerhound',
    'Sealyham Terrier',
    'Shetland Sheepdog',
    'Shih Tzu',
    'Siberian Husky',
    'Staffordshire Bullterrier',
    'Sussex Spaniel',
    'Tibetan Mastiff',
    'Tibetan Terrier',
    'Walker Hound',
    'Weimaraner',
    'Welsh Springer Spaniel',
    'West Highland White Terrier',
    'Yorkshire Terrier',
    'Affenpinscher',
    'Basenji',
    'Basset',
    'Beagle',
    'Black And Tan Coonhound',
    'Bloodhound',
    'Bluetick',
    'Borzoi',
    'Boxer',
    'Briard',
    'Bull Mastiff',
    'Cairn',
    'Chow',
    'Clumber',
    'Cocker Spaniel',
    'Collie',
    'Curly Coated Retriever',
    'Dhole',
    'Dingo',
    'Flat Coated Retriever',
    'Giant Schnauzer',
    'Golden Retriever',
    'Groenendael',
    'Keeshond',
    'Kelpie',
    'Komondor',
    'Kuvasz',
    'Malamute',
    'Malinois',
    'Miniature Pinscher',
    'Miniature Poodle',
    'Miniature Schnauzer',
    'Otterhound',
    'Papillon',
    'Pug',
    'Redbone',
    'Schipperke',
    'Silky Terrier',
    'Soft Coated Wheaten Terrier',
    'Standard Poodle',
    'Standard Schnauzer',
    'Toy Poodle',
    'Toy Terrier',
    'Vizsla',
    'Whippet',
    'Wire Haired Fox Terrier'
    ]

    input_data = preprocess_image(image_bytes)  # Preprocess input image
    model = load_compact_model()  # Load TFLite model
    input_details = model.get_input_details()
    output_details = model.get_output_details()

    model.set_tensor(input_details[0]['index'], input_data)  # Feed input to model
    model.invoke()  # Run inference
    output = model.get_tensor(output_details[0]['index'])  # Get model output

    predicted_index = np.argmax(output)  # Get predicted class index
    confidence = float(np.max(output))  # Get prediction confidence
    breed = breed_labels[predicted_index]  # Map index to breed name

    return breed, confidence

app = FastAPI()

@app.get('/')
async def root():
    return {"message": "The API is Active"}

@app.post('/predict')
async def predict(request: Request):
    image_bytes = await request.body()
    breed, confidence = image_to_label(image_bytes)
    return {"breed": breed, "confidence": confidence}
