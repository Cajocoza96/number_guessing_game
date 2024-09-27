#!/bin/bash

# Conectar a la base de datos
PSQL="psql --username=freecodecamp --dbname=number_guess -t --no-align -c"

# Solicitar nombre de usuario
echo "Enter your username:"
read USERNAME

# Verificar si el usuario ya existe
USER_RESULT=$($PSQL "SELECT user_id, games_played, best_game FROM users WHERE username='$USERNAME'")
if [[ -z $USER_RESULT ]]
then
  # Nuevo usuario
  echo "Welcome, $USERNAME! It looks like this is your first time here."
  INSERT_USER_RESULT=$($PSQL "INSERT INTO users(username) VALUES('$USERNAME')")
else
  # Usuario existente
  IFS="|" read USER_ID GAMES_PLAYED BEST_GAME <<< "$USER_RESULT"
  echo "Welcome back, $USERNAME! You have played $GAMES_PLAYED games, and your best game took $BEST_GAME guesses."
fi

# Generar un número aleatorio entre 1 y 1000
SECRET_NUMBER=$(( RANDOM % 1000 + 1 ))

# Inicializar contador de intentos
ATTEMPTS=0

echo "Guess the secret number between 1 and 1000:"
while true
do
  read GUESS

  # Verificar si el input es un número entero
  if [[ ! $GUESS =~ ^[0-9]+$ ]]
  then
    echo "That is not an integer, guess again:"
    continue
  fi

  # Incrementar el contador de intentos
  ((ATTEMPTS++))

  # Comparar el número ingresado con el número secreto
  if [[ $GUESS -eq $SECRET_NUMBER ]]
  then
    echo "You guessed it in $ATTEMPTS tries. The secret number was $SECRET_NUMBER. Nice job!"

    # Actualizar el número de juegos y la mejor marca del usuario
    if [[ -z $USER_RESULT ]]
    then
      UPDATE_USER_RESULT=$($PSQL "UPDATE users SET games_played = 1, best_game = $ATTEMPTS WHERE username='$USERNAME'")
    else
      NEW_GAMES_PLAYED=$(( GAMES_PLAYED + 1 ))
      if [[ -z $BEST_GAME || $ATTEMPTS -lt $BEST_GAME ]]
      then
        UPDATE_USER_RESULT=$($PSQL "UPDATE users SET games_played = $NEW_GAMES_PLAYED, best_game = $ATTEMPTS WHERE user_id=$USER_ID")
      else
        UPDATE_USER_RESULT=$($PSQL "UPDATE users SET games_played = $NEW_GAMES_PLAYED WHERE user_id=$USER_ID")
      fi
    fi
    break
  elif [[ $GUESS -lt $SECRET_NUMBER ]]
  then
    echo "It's higher than that, guess again:"
  else
    echo "It's lower than that, guess again:"
  fi
done
