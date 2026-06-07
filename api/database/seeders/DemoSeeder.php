<?php

namespace Database\Seeders;

use App\Models\Bike;
use App\Models\BikeModel;
use App\Models\Ride;
use App\Models\User;
use Illuminate\Database\Seeder;

class DemoSeeder extends Seeder
{
    /**
     * Demo data for API testing (Postman / Flutter).
     *
     * Users:
     *   test@example.com / password
     *   jane@example.com / password
     *
     * Run: php artisan db:seed --class=DemoSeeder
     * Or:  php artisan migrate:fresh --seed
     */
    public function run(): void
    {
        $this->call(CatalogSeeder::class);

        $testUser = User::query()->updateOrCreate(
            ['email' => 'test@example.com'],
            ['name' => 'Test User', 'password' => 'password'],
        );

        $jane = User::query()->updateOrCreate(
            ['email' => 'jane@example.com'],
            ['name' => 'Jane Doe', 'password' => 'password'],
        );

        $explore = $this->findModel('giant', 'explore-e-2');
        $domane = $this->findModel('trek', 'domane-slr-6');
        $vado = $this->findModel('specialized', 'turbo-vado-4-0');

        $giantBike = $this->seedBike($testUser, $explore, [
            'nickname' => 'My Giant',
            'serial_number' => 'SN-GIANT-001',
            'frame_number' => 'FN-GIANT-001',
            'color' => 'black',
            'odometer_km' => 0,
            'purchased_at' => '2024-01-15',
        ]);

        $this->seedBike($testUser, $domane, [
            'nickname' => 'Trek road bike',
            'serial_number' => 'SN-TREK-001',
            'color' => 'red',
            'odometer_km' => 890,
            'purchased_at' => '2024-06-20',
        ]);

        $janeBike = $this->seedBike($jane, $vado, [
            'nickname' => 'Urban Vado',
            'serial_number' => 'SN-SPEC-001',
            'frame_number' => 'FN-SPEC-001',
            'color' => 'blue',
            'odometer_km' => 0,
            'purchased_at' => '2023-11-10',
        ]);

        $this->seedRide($giantBike, [
            'distance_km' => 32,
            'started_at' => '2026-05-28 08:00:00',
            'ended_at' => '2026-05-28 09:10:00',
            'notes' => 'Commute to work',
        ]);

        $this->seedRide($giantBike, [
            'distance_km' => 18,
            'started_at' => '2026-05-30 17:30:00',
            'ended_at' => '2026-05-30 18:05:00',
            'notes' => 'Ride home',
        ]);

        $this->seedRide($janeBike, [
            'distance_km' => 45,
            'started_at' => '2026-06-01 10:00:00',
            'ended_at' => '2026-06-01 12:30:00',
            'notes' => 'Park loop',
        ]);

        $giantBike->update(['odometer_km' => $giantBike->rides()->sum('distance_km')]);
        $janeBike->update(['odometer_km' => $janeBike->rides()->sum('distance_km')]);
    }

    private function findModel(string $brandSlug, string $modelSlug): BikeModel
    {
        return BikeModel::query()
            ->where('slug', $modelSlug)
            ->whereHas('brand', fn ($query) => $query->where('slug', $brandSlug))
            ->firstOrFail();
    }

    /**
     * @param  array<string, mixed>  $attributes
     */
    private function seedBike(User $user, BikeModel $bikeModel, array $attributes): Bike
    {
        return Bike::query()->updateOrCreate(
            [
                'user_id' => $user->id,
                'serial_number' => $attributes['serial_number'] ?? null,
            ],
            [
                ...$attributes,
                'user_id' => $user->id,
                'bike_model_id' => $bikeModel->id,
            ],
        );
    }

    /**
     * @param  array<string, mixed>  $attributes
     */
    private function seedRide(Bike $bike, array $attributes): Ride
    {
        return Ride::query()->updateOrCreate(
            [
                'bike_id' => $bike->id,
                'started_at' => $attributes['started_at'],
            ],
            [
                ...$attributes,
                'user_id' => $bike->user_id,
                'bike_id' => $bike->id,
            ],
        );
    }
}
