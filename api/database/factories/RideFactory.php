<?php

namespace Database\Factories;

use App\Models\Bike;
use App\Models\Ride;
use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<Ride>
 */
class RideFactory extends Factory
{
    protected $model = Ride::class;

    /**
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        $startedAt = fake()->dateTimeBetween('-3 months', 'now');

        return [
            'user_id' => User::factory(),
            'bike_id' => Bike::factory(),
            'distance_km' => fake()->numberBetween(5, 80),
            'started_at' => $startedAt,
            'ended_at' => (clone $startedAt)->modify('+'.fake()->numberBetween(30, 180).' minutes'),
            'notes' => fake()->optional()->sentence(),
        ];
    }
}
