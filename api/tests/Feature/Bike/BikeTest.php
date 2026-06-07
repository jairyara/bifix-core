<?php

declare(strict_types=1);

use App\Models\Bike;
use App\Models\BikeModel;
use App\Models\User;
use Laravel\Sanctum\Sanctum;

use function Pest\Laravel\assertDatabaseHas;
use function Pest\Laravel\assertDatabaseMissing;
use function Pest\Laravel\deleteJson;
use function Pest\Laravel\getJson;
use function Pest\Laravel\postJson;
use function Pest\Laravel\putJson;

test('authenticated users can list their bikes', function () {
    $user = User::factory()->create();
    $otherUser = User::factory()->create();
    $bikeModel = BikeModel::factory()->create();

    $userBike = Bike::factory()->create([
        'user_id' => $user->id,
        'bike_model_id' => $bikeModel->id,
    ]);

    Bike::factory()->create([
        'user_id' => $otherUser->id,
        'bike_model_id' => $bikeModel->id,
    ]);

    Sanctum::actingAs($user);

    getJson('/api/v1/bikes')
        ->assertOk()
        ->assertJsonCount(1, 'data')
        ->assertJsonPath('data.0.id', $userBike->id)
        ->assertJsonStructure([
            'data' => [
                '*' => [
                    'id',
                    'serial_number',
                    'frame_number',
                    'nickname',
                    'color',
                    'odometer_km',
                    'purchased_at',
                    'model' => [
                        'id',
                        'name',
                        'slug',
                        'brand' => ['id', 'name', 'slug'],
                        'battery_type' => ['id', 'name', 'slug'],
                    ],
                    'created_at',
                    'updated_at',
                ],
            ],
        ]);
});

test('guests cannot list bikes', function () {
    getJson('/api/v1/bikes')->assertUnauthorized();
});

test('authenticated users can create a bike', function () {
    $user = User::factory()->create();
    $bikeModel = BikeModel::factory()->create();

    Sanctum::actingAs($user);

    postJson('/api/v1/bikes', [
        'bike_model_id' => $bikeModel->id,
        'nickname' => 'Mi e-bike',
        'color' => 'red',
        'odometer_km' => 1200,
        'purchased_at' => '2024-03-15',
    ])
        ->assertCreated()
        ->assertJsonPath('data.nickname', 'Mi e-bike')
        ->assertJsonPath('data.model.id', $bikeModel->id);

    assertDatabaseHas('bikes', [
        'user_id' => $user->id,
        'bike_model_id' => $bikeModel->id,
        'nickname' => 'Mi e-bike',
        'odometer_km' => 1200,
    ]);
});

test('creating a bike requires a valid bike model', function () {
    $user = User::factory()->create();

    Sanctum::actingAs($user);

    postJson('/api/v1/bikes', [
        'nickname' => 'Mi e-bike',
    ])
        ->assertUnprocessable()
        ->assertJsonValidationErrors(['bike_model_id']);
});

test('authenticated users can view their own bike', function () {
    $user = User::factory()->create();
    $bike = Bike::factory()->create(['user_id' => $user->id]);

    Sanctum::actingAs($user);

    getJson("/api/v1/bikes/{$bike->id}")
        ->assertOk()
        ->assertJsonPath('data.id', $bike->id);
});

test('users cannot view another users bike', function () {
    $user = User::factory()->create();
    $otherUser = User::factory()->create();
    $bike = Bike::factory()->create(['user_id' => $otherUser->id]);

    Sanctum::actingAs($user);

    getJson("/api/v1/bikes/{$bike->id}")->assertNotFound();
});

test('authenticated users can update their own bike', function () {
    $user = User::factory()->create();
    $newBikeModel = BikeModel::factory()->create();
    $bike = Bike::factory()->create(['user_id' => $user->id]);

    Sanctum::actingAs($user);

    putJson("/api/v1/bikes/{$bike->id}", [
        'bike_model_id' => $newBikeModel->id,
        'nickname' => 'Actualizada',
        'odometer_km' => 5000,
    ])
        ->assertOk()
        ->assertJsonPath('data.nickname', 'Actualizada')
        ->assertJsonPath('data.model.id', $newBikeModel->id);

    assertDatabaseHas('bikes', [
        'id' => $bike->id,
        'bike_model_id' => $newBikeModel->id,
        'nickname' => 'Actualizada',
        'odometer_km' => 5000,
    ]);
});

test('users cannot update another users bike', function () {
    $user = User::factory()->create();
    $otherUser = User::factory()->create();
    $bike = Bike::factory()->create(['user_id' => $otherUser->id]);

    Sanctum::actingAs($user);

    putJson("/api/v1/bikes/{$bike->id}", [
        'nickname' => 'Hackeada',
    ])->assertNotFound();
});

test('authenticated users can delete their own bike', function () {
    $user = User::factory()->create();
    $bike = Bike::factory()->create(['user_id' => $user->id]);

    Sanctum::actingAs($user);

    deleteJson("/api/v1/bikes/{$bike->id}")
        ->assertNoContent();

    assertDatabaseMissing('bikes', ['id' => $bike->id]);
});

test('users cannot delete another users bike', function () {
    $user = User::factory()->create();
    $otherUser = User::factory()->create();
    $bike = Bike::factory()->create(['user_id' => $otherUser->id]);

    Sanctum::actingAs($user);

    deleteJson("/api/v1/bikes/{$bike->id}")->assertNotFound();

    assertDatabaseHas('bikes', ['id' => $bike->id]);
});
