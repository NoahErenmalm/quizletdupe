let currentQuestionIndex = 0;
let incorrectAnswers = [];


document.addEventListener("DOMContentLoaded", function() {
  showQuestion(currentQuestionIndex);

  const replayButton = document.getElementById("replay-button");
  if (replayButton) {
    replayButton.addEventListener("click", restartQuiz)
  }
});

function restartQuiz() {
  currentQuestionIndex = 0;
  incorrectAnswers = [];

  const resultContainer = document.getElementById("result-container");
  if (resultContainer) {
    resultContainer.style.display = "none";

    // Clear the incorrect answers list
    const incorrectList = document.getElementById("incorrect-list");
    if (incorrectList) {
      incorrectList.innerHTML = ""; // Clear the list items
    }
  }

  // Hide all question divs and reset their state
  const questionDivs = document.querySelectorAll(".question-div");
  questionDivs.forEach((div) => {
    div.style.display = "none"; // Hide the question
    const userInput = div.querySelector("input[type='text']");
    if (userInput) {
      userInput.value = ""; // Clear the user input field
    }
  });

  // Restart the quiz
  showQuestion(currentQuestionIndex);
}

function showQuestion(index) {
  const currentQuestionDiv = document.getElementById(`question-${index}`);
  if (currentQuestionDiv) {
    currentQuestionDiv.style.display = "block";

    const userInput = document.getElementById(`user-input-${index}`);
    if (userInput) {
      userInput.focus();
    }
  }
}
function hideQuestion(index) {
  const currentQuestionDiv = document.getElementById(`question-${index}`);
  if (currentQuestionDiv) {
    currentQuestionDiv.style.display = "none";
  }
}

function checkAnswer(index) {
  const userInput = document.getElementById(`user-input-${index}`).value.trim();
  const correctAnswer = document.getElementById(`correct-answer-${index}`).value.trim();

  if (userInput.toLowerCase() !== correctAnswer.toLowerCase()) {
    incorrectAnswers.push({
      questionIndex: index,
      userInput: userInput,
      correctAnswer: correctAnswer
    });
  }

  hideQuestion(index);
  currentQuestionIndex++;

  const nextQuestionDiv = document.getElementById(`question-${currentQuestionIndex}`);
  if (nextQuestionDiv) {
    showQuestion(currentQuestionIndex);
  } else {
    showResults();
  }


  return false; // Prevent form submission
}


function showResults() {
  const resultContainer = document.getElementById("result-container");
  if (resultContainer) {
    resultContainer.style.display = "block";

    const scoreElement = document.getElementById("score");
    if (scoreElement) {
      const totalQuestions = currentQuestionIndex;
      const correctAnswers = totalQuestions - incorrectAnswers.length;
      scoreElement.textContent = `Score: ${correctAnswers} / ${totalQuestions}`;
    }

    const incorrectList = document.getElementById("incorrect-list");
    if (incorrectList) {
      incorrectAnswers.forEach((item) => {
        const listItem = document.createElement("li");

        // Add image if available
        const questionDiv = document.getElementById(`question-${item.questionIndex}`);
        const image = questionDiv.querySelector("img");
        if (image) {
          const imgElement = document.createElement("img");
          imgElement.src = image.src;
          imgElement.alt = image.alt;
          listItem.appendChild(imgElement);
        }

        // Add question text
        const questionText = questionDiv.querySelector("h2");
        if (questionText) {
          const questionTextElement = document.createElement("p");
          questionTextElement.textContent = questionText.textContent;
          listItem.appendChild(questionTextElement);
        }

        // Add correct answer
        const correctAnswerText = document.createElement("p");
        correctAnswerText.textContent = `Correct answer: "${item.correctAnswer}"`;
        listItem.appendChild(correctAnswerText);

        // Add user's answer
        const userAnswerText = document.createElement("p");
        userAnswerText.textContent = `Your answer: "${item.userInput}"`;
        listItem.appendChild(userAnswerText);

        incorrectList.appendChild(listItem);
      });
    }
  }
}

