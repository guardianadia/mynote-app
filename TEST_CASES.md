## Test Case Group: AuthService Unit Testing
### Testing Type
This set of tests will be classified as unit testing because I isolated the AuthService class. I focused on one function at a time. Each test was done on certain features of the authentication process. For example, login, logout, and password reset.

I also tested how the system manages errors. For example, in the case of invalid login, or invalid email format. Valid email was used to do negative testing. White box testing. As I'm testing the internal logic of the code.

These tests verify the authentication system processes and invalid inputs are handled safely.


## edit_note_screen_test.dart

Confirm that the load screen for the EditNoteScreen appears without any errors
Confirm that the input fields are within the needed user interaction specification
Simulates user input interaction within a user input field
Verify if the input text appears
The presence of interactive elements is confirmed if action buttons notify and allow the user to call for action recommend
Overall, all these tests the EditNoteScreen to confirm that the user is able to actively engage in the interface.

## forgot_screens_test.dart
This file contains **widget tests** for the Forgot Username and Forgot Password screens.

It also includes:
Input validation testing which gives empty, valid, and invalid inputs
Positive testing (valid inputs work correctly)
Negative testing (invalid or empty inputs show errors)
Functional testing the buttons and user actions work
Basic stability testing this ensures the app does not crash

## note_service_test.dart
Summary:
This file tests the app's NoteService class. It checks if functions in the app related to note management do not crash the app.

Test Type:
This file contains unit tests for NoteService's logic and functions.

This class also contains:

Functional Testing is to ensure methods perform their intended function
Stability Testing is to ensure the app doesn't crash
Data validation Testing is to ensure the returned data is of the correct type
Instructions
The system initializes the following applications in order to run the tests:

Shared Preferences (to assist in local storage)
Supabase (to assist in the backend)
Hive (used to store the notes in-app)
When tests run, there is a Hive database created to stand in for the local storage.

Test Cases
 Validating that getNotes returns a List
Make the call to getNotes()

Validate that a List is returned

Validating that saveNote does not crash
Create a sample note

Save the sample note by calling saveNote()

Validate that the function returns without crashing

Validating that deleteNote does not crash
Call deleteNote() and pass in a test ID

Validate that the function returns without crashing

Validating that Hive box is created
Validate that the Hive storage box is created

Validate the local storage creation

End Note
In short, the functions of NoteService do not crash and and save notes in both online and offline storage. Authentication tests can be written on online services but it is not in the scope of offline services. Interface and usability tests are also beyond the scope of this functionality module.

## note_test.dart
Type of Test
This is a unit test. It is going to test a Note model data structure NOT the UI.

Explanation
This test is checking the storage and manipulation of the Note data. An example of the data is a title, content, folder, and tags. This test is checking if all of these values are stored correctly.

This test also creates different instances of notes to check if the values can be:

Initialization of proper data
No title and other values left empty ->this includes other annotations, tags, and etc.
Unique note IDs
Data collection to and conversion from the map for the purpose of storage and databases
This test also has edge cases with:

Fields missing from older data
Tags as a string in place of a list
App crashes if invalid date values are present
Summary
This test ensures that the Note model is efficient, is flexible in terms of data, and does not fail if data provided is not as expected.

# widget_test.dart
Stable Widget Tests
What Is Being Tested
This is a widget test. They test for the app's user interface( UI) screens to see how well they work and if they crash on load.

Description
This test verifies that the app's main screens load with the correct displays for the:

Forgot Username.

Forgot Password.

Edit Note.

It also tests for user interaction by typing into a text field.

The reason for the test is to see if the app and UI are stable and won't crash when the users access the app.

Conclusion
This test ensures that the main screens are built correctly and the user interaction is without error.