<?php

declare(strict_types=1);

use App\Models\BatteryType;
use App\Models\BikeModel;
use App\Models\Brand;
use Laravel\Sanctum\Sanctum;
use App\Models\User;

use function Pest\Laravel\getJson;

test('authenticated users can list brands', function () {
    Brand::factory()->count(3)->create();

    Sanctum::actingAs(User::factory()->create());

    getJson('/api/v1/brands')
        ->assertOk()
        ->assertJsonCount(3, 'data')
        ->assertJsonStructure([
            'data' => [
                '*' => ['id', 'name', 'slug'],
            ],
        ]);
});

test('authenticated users can list bike models filtered by brand', function () {
    $brand = Brand::factory()->create();
    $otherBrand = Brand::factory()->create();

    BikeModel::factory()->count(2)->create(['brand_id' => $brand->id]);
    BikeModel::factory()->create(['brand_id' => $otherBrand->id]);

    Sanctum::actingAs(User::factory()->create());

    getJson("/api/v1/bike-models?brand_id={$brand->id}")
        ->assertOk()
        ->assertJsonCount(2, 'data')
        ->assertJsonStructure([
            'data' => [
                '*' => [
                    'id',
                    'name',
                    'slug',
                    'year',
                    'frame_type',
                    'motor_brand',
                    'battery_wh',
                    'range_km',
                    'brand' => ['id', 'name', 'slug'],
                    'battery_type' => ['id', 'name', 'slug'],
                ],
            ],
        ]);
});

test('authenticated users can show a bike model', function () {
    $bikeModel = BikeModel::factory()->create();

    Sanctum::actingAs(User::factory()->create());

    getJson("/api/v1/bike-models/{$bikeModel->id}")
        ->assertOk()
        ->assertJsonPath('data.id', $bikeModel->id);
});

test('authenticated users can list active battery types', function () {
    BatteryType::factory()->create(['name' => 'Lithium', 'slug' => 'lithium', 'is_active' => true]);
    BatteryType::factory()->create(['name' => 'Obsolete', 'slug' => 'obsolete', 'is_active' => false]);

    Sanctum::actingAs(User::factory()->create());

    getJson('/api/v1/battery-types')
        ->assertOk()
        ->assertJsonCount(1, 'data')
        ->assertJsonPath('data.0.slug', 'lithium');
});

test('guests cannot access catalog endpoints', function () {
    getJson('/api/v1/brands')->assertUnauthorized();
    getJson('/api/v1/bike-models')->assertUnauthorized();
    getJson('/api/v1/battery-types')->assertUnauthorized();
});
