<?php

declare(strict_types=1);

use App\Models\Bike;
use App\Models\BikeModel;
use App\Models\Ride;
use App\Models\User;
use Laravel\Sanctum\Sanctum;

use function Pest\Laravel\assertDatabaseHas;
use function Pest\Laravel\assertDatabaseMissing;
use function Pest\Laravel\deleteJson;
use function Pest\Laravel\getJson;
use function Pest\Laravel\postJson;
use function Pest\Laravel\putJson;

test('authenticated users can list rides for their bike', function () {
    $user = User::factory()->create();
    $bike = Bike::factory()->create(['user_id' => $user->id]);
    $otherBike = Bike::factory()->create();

    Ride::factory()->create([
        'user_id' => $user->id,
        'bike_id' => $bike->id,
        'distance_km' => 25,
    ]);

    Ride::factory()->create([
        'bike_id' => $otherBike->id,
        'distance_km' => 10,
    ]);

    Sanctum::actingAs($user);

    getJson("/api/v1/bikes/{$bike->id}/rides")
        ->assertOk()
        ->assertJsonCount(1, 'data')
        ->assertJsonPath('data.0.distance_km', 25)
        ->assertJsonStructure([
            'data' => [
                '*' => [
                    'id',
                    'bike_id',
                    'distance_km',
                    'started_at',
                    'ended_at',
                    'notes',
                    'created_at',
                    'updated_at',
                ],
            ],
        ]);
});

test('authenticated users can register a ride and odometer is updated', function () {
    $user = User::factory()->create();
    $bike = Bike::factory()->create([
        'user_id' => $user->id,
        'odometer_km' => 100,
    ]);

    Sanctum::actingAs($user);

    postJson("/api/v1/bikes/{$bike->id}/rides", [
        'distance_km' => 32,
        'started_at' => '2026-06-01T08:00:00+00:00',
        'ended_at' => '2026-06-01T09:15:00+00:00',
        'notes' => 'Commute to work',
    ])
        ->assertCreated()
        ->assertJsonPath('data.distance_km', 32)
        ->assertJsonPath('data.bike_id', $bike->id);

    assertDatabaseHas('rides', [
        'bike_id' => $bike->id,
        'user_id' => $user->id,
        'distance_km' => 32,
        'notes' => 'Commute to work',
    ]);

    expect($bike->fresh()->odometer_km)->toBe(132);
});

test('creating a ride requires distance', function () {
    $user = User::factory()->create();
    $bike = Bike::factory()->create(['user_id' => $user->id]);

    Sanctum::actingAs($user);

    postJson("/api/v1/bikes/{$bike->id}/rides", [])
        ->assertUnprocessable()
        ->assertJsonValidationErrors(['distance_km']);
});

test('users cannot register rides on another users bike', function () {
    $user = User::factory()->create();
    $otherUser = User::factory()->create();
    $bike = Bike::factory()->create(['user_id' => $otherUser->id]);

    Sanctum::actingAs($user);

    postJson("/api/v1/bikes/{$bike->id}/rides", [
        'distance_km' => 10,
    ])->assertNotFound();
});

test('authenticated users can update a ride and odometer is adjusted', function () {
    $user = User::factory()->create();
    $bike = Bike::factory()->create([
        'user_id' => $user->id,
        'odometer_km' => 150,
    ]);

    $ride = Ride::factory()->create([
        'user_id' => $user->id,
        'bike_id' => $bike->id,
        'distance_km' => 50,
    ]);

    Sanctum::actingAs($user);

    putJson("/api/v1/bikes/{$bike->id}/rides/{$ride->id}", [
        'distance_km' => 60,
        'notes' => 'Corrected distance',
    ])
        ->assertOk()
        ->assertJsonPath('data.distance_km', 60);

    expect($bike->fresh()->odometer_km)->toBe(160);
});

test('authenticated users can delete a ride and odometer is reduced', function () {
    $user = User::factory()->create();
    $bike = Bike::factory()->create([
        'user_id' => $user->id,
        'odometer_km' => 80,
    ]);

    $ride = Ride::factory()->create([
        'user_id' => $user->id,
        'bike_id' => $bike->id,
        'distance_km' => 30,
    ]);

    Sanctum::actingAs($user);

    deleteJson("/api/v1/bikes/{$bike->id}/rides/{$ride->id}")
        ->assertNoContent();

    assertDatabaseMissing('rides', ['id' => $ride->id]);
    expect($bike->fresh()->odometer_km)->toBe(50);
});

test('users cannot access rides from another users bike', function () {
    $user = User::factory()->create();
    $otherUser = User::factory()->create();
    $bike = Bike::factory()->create(['user_id' => $otherUser->id]);
    $ride = Ride::factory()->create([
        'user_id' => $otherUser->id,
        'bike_id' => $bike->id,
    ]);

    Sanctum::actingAs($user);

    getJson("/api/v1/bikes/{$bike->id}/rides/{$ride->id}")->assertNotFound();
});
