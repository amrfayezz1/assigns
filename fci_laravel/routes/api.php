<?php

use Illuminate\Http\Request;
use App\Models\User;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\ValidationException;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Facades\Storage;

// REGISTER USER
Route::post('/register', function (Request $request) {
    $validator = Validator::make($request->all(), [
        'name' => 'required|string',
        'email' => [
            'required',
            'email',
            'unique:users',
            function ($attribute, $value, $fail) use ($request) {
                if (!preg_match('/^(\d{8})@stud\.fci-cu\.edu\.eg$/', $value, $matches)) {
                    return $fail('The email must be in the format: studentID@stud.fci-cu.edu.eg');
                }

                if ($request->student_id !== $matches[1]) {
                    return $fail('The student ID must match the ID in the email.');
                }
            },
        ],
        'student_id' => 'required|digits:8|unique:users',
        'password' => 'required|min:8|confirmed',
        'gender' => 'nullable|in:Male,Female',
        'level' => 'nullable|in:1,2,3,4',
    ]);

    if ($validator->fails()) {
        throw new ValidationException($validator);
    }

    $user = User::create([
        'name' => $request->name,
        'email' => $request->email,
        'student_id' => $request->student_id,
        'level' => $request->level,
        'gender' => $request->gender,
        'password' => Hash::make($request->password),
    ]);

    $token = $user->createToken('auth_token')->plainTextToken;

    return response()->json([
        'success' => true,
        'token' => $token,
        'name' => $user->name,
        'message' => 'Registration successful!',
    ]);
});

// LOGIN USER
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

// LOGOUT USER
Route::middleware('auth:sanctum')->post('/logout', function (Request $request) {
    $request->user()->tokens()->delete();

    return response()->json([
        'success' => true,
        'message' => 'Logged out successfully!',
    ]);
});

// GET USER DATA
Route::middleware('auth:sanctum')->get('/user', function (Request $request) {
    return response()->json([
        'success' => true,
        'user' => [
            'id' => $request->user()->id,
            'name' => $request->user()->name,
            'email' => $request->user()->email,
            'profile_picture' => $request->user()->profile_picture
                ? asset('storage/' . $request->user()->profile_picture)
                : null,

        ]
    ]);
});

// UPDATE PROFILE
Route::middleware('auth:sanctum')->post('/update-profile', function (Request $request) {
    $user = $request->user();
    $updated = false;

    $validator = Validator::make($request->all(), [
        'name' => 'nullable|string|max:255|min:3',
        'password' => [
            'nullable',
            'string',
            'min:8',
            'confirmed',
            'regex:/^(?=.*\d).{8,}$/',
        ],
    ], [
        'password.regex' => 'Password must be at least 8 characters with at least 1 number.',
    ]);

    if ($validator->fails()) {
        return response()->json([
            'success' => false,
            'errors' => $validator->errors(),
        ], 422);
    }

    if ($request->filled('name') && $request->name !== $user->name) {
        $user->name = $request->name;
        $updated = true;
    }

    if ($request->filled('password')) {
        $user->password = Hash::make($request->password);
        $updated = true;
    }

    if ($updated) {
        $user->save();
        return response()->json([
            'success' => true,
            'message' => 'Profile updated successfully!',
            'user' => $user,
        ]);
    }

    return response()->json([
        'success' => false,
        'message' => 'No changes were made.',
    ], 400);
});

// UPDATE PROFILE PHOTO
Route::middleware('auth:sanctum')->post('/update-photo', function (Request $request) {
    $user = $request->user();

    // Validate the image
    $validator = Validator::make($request->all(), [
        'photo' => 'required|image|mimes:jpg,jpeg,png|max:2048',
    ]);

    if ($validator->fails()) {
        return response()->json(['success' => false, 'errors' => $validator->errors()], 422);
    }

    // Delete old profile picture if exists
    if ($user->profile_picture) {
        Storage::delete('public/' . $user->profile_picture);
    }

    // Store new profile picture
    $path = $request->file('photo')->store('profile_pictures', 'public');
    $user->profile_picture = $path;
    $user->save();

    return response()->json([
        'success' => true,
        'message' => 'Profile photo updated!',
        'photo_url' => Storage::url($path) // Full URL
    ]);
});