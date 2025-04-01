document.addEventListener('DOMContentLoaded', function() {
    var addButton = document.getElementById('add-question-button');

    function updateRemoveButtons() {
        var questionBoxes = document.querySelectorAll('.quiz-create-question-box');
        questionBoxes.forEach(function(box, index) {
            var removeButton = box.querySelector('.remove-question-button');
            if (questionBoxes.length === 1) {
                removeButton.disabled = true; // Disable remove button if it's the last question
            } else {
                removeButton.disabled = false; // Enable remove button otherwise
            }
        });
    }

    addButton.addEventListener('click', function() {
        var container = document.getElementById('questions-container');
        var template = container.querySelector('.quiz-create-question-box');
        var newBox = template.cloneNode(true);

        // Clear the input values
        var questionInput = newBox.querySelector('input[name="questions_text[]"]');
        var answerInput = newBox.querySelector('input[name="answers[]"]');
        var imageInput = newBox.querySelector('input[name="questions_image[]"]');
        if (questionInput) questionInput.value = '';
        if (answerInput) answerInput.value = '';
        if (imageInput) imageInput.value = '';

        // Add event listener to the remove button
        var removeButton = newBox.querySelector('.remove-question-button');
        removeButton.addEventListener('click', function() {
            newBox.remove();
            updateRemoveButtons(); // Update remove button states
        });

        container.appendChild(newBox);
        updateRemoveButtons(); // Update remove button states
    });

    // Add event listener to the initial remove button (if it exists)
    var initialRemoveButtons = document.querySelectorAll('.remove-question-button');
    initialRemoveButtons.forEach(function(button) {
        button.addEventListener('click', function() {
            button.closest('.quiz-create-question-box').remove();
            updateRemoveButtons(); // Update remove button states
        });
    });

    // Add event listener for "Remove Image" buttons
    document.addEventListener('click', function(event) {
        if (event.target && event.target.dataset.action === 'remove-image') {
            var parentBox = event.target.closest('.quiz-create-question-box');
            if (parentBox) {
                // Remove the image and replace with a file input
                parentBox.querySelector('img').remove();

                var hiddenInputWithValue = parentBox.querySelector('input[type="hidden"][name="questions_image[]"][value]');
                if (hiddenInputWithValue) {
                    hiddenInputWithValue.remove();
                
                }
                event.target.remove(); // Remove the "Remove Image" button

                // Add a new file input at the beginning of the container
                var fileInput = document.createElement('input');
                fileInput.type = 'file';
                fileInput.name = 'questions_image[]';
                fileInput.accept = 'image/png, image/jpg, image/jpeg';

                var hiddenInput = parentBox.querySelector('input[type="hidden"][name="questions_image[]"]');
                if (hiddenInput) {
                    hiddenInput.insertAdjacentElement('afterend', fileInput);
                }
            }
        }
    });
    updateRemoveButtons(); // Initialize remove button states
});