from flask import Flask, jsonify, request

app = Flask(__name__)

# A simple list to store movies
movies = [
    {'id': 1, 'title': 'RRR', 'director': 'SS Rajamouli'},
    {'id': 2, 'title': 'Pushpa', 'director': 'Sukumar'}
]

# Route to get all movies
@app.route('/movies', methods=['GET'])
def get_movies():
    return jsonify(movies), 200

# Route to add a new movie
@app.route('/movies', methods=['POST'])
def add_movie():
    new_movie = request.get_json()
    new_movie['id'] = len(movies) + 1  # Automatically assign an ID
    movies.append(new_movie)
    return jsonify(new_movie), 201

if __name__ == '__main__':
    app.run(debug=True)
