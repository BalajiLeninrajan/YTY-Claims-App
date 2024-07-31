# YTY CLAIMS APP 

App for YTY employees to submit expense claims.

## Getting Started

This project requires a bearer token to access YTY APIs. 
Once the project is cloned:
- Create a file called `api_constants.dart` in the **lib/** directory
- Create a constant String variable with the name `bearerToken` and set the token as its value i.e. 
```dart
const String bearerToken = 'Bearer [token here]';
```
- Create a constant String variable with the name `apiUrl` and set the api url as it's value
```dart
const String apiUrl = 'https://ytygroup.app/claim-api/api/';
```