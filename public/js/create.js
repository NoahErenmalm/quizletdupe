document.addEventListener('DOMContentLoaded', function() {
  var addButton = document.getElementById('add-question-button');

  var removeButton = document.getElementById('remove-question-button');

  removeButton.addEventListener('click', function()) {
        

  }
  
  addButton.addEventListener('click', function() {
    
    var container = document.getElementById('questions-container');
        
    var template = container.querySelector('.quiz-create-question-box');
    
    var newBox = template.cloneNode(true);
    
    // clear the input values
    var questionInput = newBox.querySelector('input[name="questions_text[]"]');
    var answerInput = newBox.querySelector('input[name="answers[]"]');
    var imageInput = newBox.querySelector('input[name="questions_image[]"')
    if (questionInput) questionInput.value = '';
    if (answerInput) answerInput.value = '';
    if (imageInput) imageInput.value = '';
    
    container.appendChild(newBox);
  });
});
