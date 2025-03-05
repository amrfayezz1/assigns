<?php

use Illuminate\Http\Request;
use App\Models\User;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\ValidationException;
use Illuminate\Support\Facades\Validator;

Route::post('/register', function (Request $request) {
    // Custom validation logic
    $validator = Validator::make($request->all(), [
        'name' => 'required|string',
        'email' => [
            'required',
            'email',
            'unique:users',
            function ($attribute, $value, $fail) use ($request) {
                // Ensure email matches the student format
                if (!preg_match('/^(\d{8})@stud\.fci-cu\.edu\.eg$/', $value, $matches)) {
                    return $fail('The email must be in the format: studentID@stud.fci-cu.edu.eg');
                }

                // Ensure student_id matches the ID extracted from email
                if ($request->student_id !== $matches[1]) {
                    return $fail('The student ID must match the ID in the email.');
                }
            },
        ],
        'student_id' => 'required|digits:8|unique:users',
        'password' => 'required|min:8|confirmed',
        'gender' => 'nullable|in:male,female',
        'level' => 'nullable|in:1,2,3,4',
    ]);

    if ($validator->fails()) {
        throw new ValidationException($validator);
    }

    // Create user
    $user = User::create([
        'name' => $request->name,
        'email' => $request->email,
        'student_id' => $request->student_id,
        'level' => $request->level,
        'gender' => $request->gender,
        'password' => Hash::make($request->password),
    ]);

    // Generate token
    $token = $user->createToken('auth_token')->plainTextToken;

    return response()->json([
        'success' => true,
        'token' => $token,
        'name' => $user->name,
        'message' => 'Registration successful!',
    ]);
});

// Login Route
Route::post('/login', function (Request $request) {
    $request->validate([
        'email' => 'required|email',
        'password' => 'required',
    ]);

    $user = User::where('email', $request->email)->first();

    if (!$user || !Hash::check($request->password, $user->password)) {
        return response()->json([
            'success' => false,
            'message' => 'Invalid email or password!',
        ], 401);
    }

    $token = $user->createToken('auth_token')->plainTextToken;

    return response()->json([
        'success' => true,
        'token' => $token,
        'name' => $user->name,
        'message' => 'Login successful!',
    ]);
});

// Logout Route
Route::middleware('auth:sanctum')->post('/logout', function (Request $request) {
    $request->user()->tokens()->delete();

    return response()->json([
        'success' => true,
        'message' => 'Logged out successfully!',
    ]);
});

// Get User Route
Route::middleware('auth:sanctum')->get('/user', function (Request $request) {
    return response()->json([
        'success' => true,
        'user' => $request->user(),
    ]);
});
