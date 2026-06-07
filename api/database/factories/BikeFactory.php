<?php

namespace Database\Factories;

use App\Models\Bike;
use App\Models\BikeModel;
use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<Bike>
 */
class BikeFactory extends Factory
{
    /**
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        return [
            'user_id' => User::factory(),
            'bike_model_id' => BikeModel::factory(),
            'serial_number' => fake()->optional()->bothify('SN-####-????'),
            'frame_number' => fake()->optional()->bothify('FN-########'),
            'nickname' => fake()->optional()->words(2, true),
            'color' => fake()->optional()->safeColorName(),
            'odometer_km' => fake()->optional()->numberBetween(0, 15000),
            'purchased_at' => fake()->optional()->date(),
        ];
    }
}
