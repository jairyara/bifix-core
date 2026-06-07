<?php

declare(strict_types=1);

use App\Models\User;
use Illuminate\Support\Facades\Hash;
use Laravel\Sanctum\PersonalAccessToken;
use Laravel\Sanctum\Sanctum;

use function Pest\Laravel\assertDatabaseHas;
use function Pest\Laravel\postJson;

test('users can register and receive an api token', function () {
    $response = postJson('/api/v1/auth/register', [
        'name' => 'Jane Doe',
        'email' => 'jane@example.com',
        'password' => 'password',
        'password_confirmation' => 'password',
        'device_name' => 'iPhone 17',
    ]);

    $response
        ->assertCreated()
        ->assertJsonPath('data.user.email', 'jane@example.com')
        ->assertJsonPath('data.user.name', 'Jane Doe')
        ->assertJsonStructure([
            'data' => [
                'user' => ['id', 'name', 'email', 'email_verified_at', 'created_at', 'updated_at'],
                'token',
            ],
        ]);

    assertDatabaseHas('users', [
        'email' => 'jane@example.com',
        'name' => 'Jane Doe',
    ]);
});

test('registration requires valid input', function () {
    postJson('/api/v1/auth/register', [])
        ->assertUnprocessable()
        ->assertJsonValidationErrors(['name', 'email', 'password', 'device_name']);
});

test('users cannot register with a duplicate email', function () {
    User::factory()->create(['email' => 'jane@example.com']);

    postJson('/api/v1/auth/register', [
        'name' => 'Jane Doe',
        'email' => 'jane@example.com',
        'password' => 'password',
        'password_confirmation' => 'password',
        'device_name' => 'iPhone 17',
    ])->assertUnprocessable()
        ->assertJsonValidationErrors(['email']);
});

test('users can login with valid credentials', function () {
    User::factory()->create([
        'email' => 'jane@example.com',
        'password' => Hash::make('password'),
    ]);

    $response = postJson('/api/v1/auth/login', [
        'email' => 'jane@example.com',
        'password' => 'password',
        'device_name' => 'Android',
    ]);

    $response
        ->assertOk()
        ->assertJsonPath('data.user.email', 'jane@example.com')
        ->assertJsonStructure([
            'data' => [
                'user' => ['id', 'name', 'email'],
                'token',
            ],
        ]);
});

test('users cannot login with invalid credentials', function () {
    User::factory()->create([
        'email' => 'jane@example.com',
        'password' => Hash::make('password'),
    ]);

    postJson('/api/v1/auth/login', [
        'email' => 'jane@example.com',
        'password' => 'wrong-password',
        'device_name' => 'Android',
    ])->assertUnprocessable()
        ->assertJsonValidationErrors(['email']);
});

test('authenticated users can view their profile', function () {
    $user = User::factory()->create();

    Sanctum::actingAs($user);

    $this->getJson('/api/v1/auth/me')
        ->assertOk()
        ->assertJsonPath('data.id', $user->id)
        ->assertJsonPath('data.email', $user->email);
});

test('guests cannot view their profile', function () {
    $this->getJson('/api/v1/auth/me')->assertUnauthorized();
});

test('authenticated users can logout and revoke their token', function () {
    $user = User::factory()->create();
    $token = $user->createToken('test-device')->plainTextToken;

    $this->withToken($token)
        ->postJson('/api/v1/auth/logout')
        ->assertOk()
        ->assertJsonPath('message', 'Logged out successfully.');

    expect(PersonalAccessToken::count())->toBe(0);

    $this->app['auth']->forgetGuards();

    $this->withToken($token)
        ->getJson('/api/v1/auth/me')
        ->assertUnauthorized();
});

test('guests cannot logout', function () {
    $this->postJson('/api/v1/auth/logout')->assertUnauthorized();
});
