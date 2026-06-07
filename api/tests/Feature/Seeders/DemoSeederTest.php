<?php

declare(strict_types=1);

use App\Models\Bike;
use App\Models\BikeModel;
use App\Models\Brand;
use App\Models\Ride;
use App\Models\User;
use Database\Seeders\DemoSeeder;

use function Pest\Laravel\assertDatabaseHas;

test('demo seeder creates catalog, users, bikes and rides', function () {
    $this->seed(DemoSeeder::class);

    expect(Brand::query()->count())->toBe(3);
    expect(BikeModel::query()->count())->toBe(5);
    expect(User::query()->count())->toBe(2);
    expect(Bike::query()->count())->toBe(3);
    expect(Ride::query()->count())->toBe(3);

    assertDatabaseHas('users', [
        'email' => 'test@example.com',
        'name' => 'Test User',
    ]);

    assertDatabaseHas('users', [
        'email' => 'jane@example.com',
        'name' => 'Jane Doe',
    ]);

    assertDatabaseHas('bikes', [
        'serial_number' => 'SN-GIANT-001',
        'nickname' => 'My Giant',
        'odometer_km' => 50,
    ]);

    assertDatabaseHas('bikes', [
        'serial_number' => 'SN-SPEC-001',
        'nickname' => 'Urban Vado',
        'odometer_km' => 45,
    ]);
});

test('demo seeder is idempotent', function () {
    $this->seed(DemoSeeder::class);
    $this->seed(DemoSeeder::class);

    expect(User::query()->count())->toBe(2);
    expect(Bike::query()->count())->toBe(3);
    expect(Ride::query()->count())->toBe(3);
});
