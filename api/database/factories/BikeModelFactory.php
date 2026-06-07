<?php

namespace Database\Factories;

use App\Models\BatteryType;
use App\Models\BikeModel;
use App\Models\Brand;
use Illuminate\Database\Eloquent\Factories\Factory;
use Illuminate\Support\Str;

/**
 * @extends Factory<BikeModel>
 */
class BikeModelFactory extends Factory
{
    /**
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        $name = fake()->words(3, true);

        return [
            'brand_id' => Brand::factory(),
            'battery_type_id' => BatteryType::factory(),
            'name' => $name,
            'slug' => Str::slug($name),
            'year' => fake()->numberBetween(2018, 2026),
            'frame_type' => fake()->randomElement(['city', 'mtb', 'road']),
            'motor_brand' => fake()->optional()->company(),
            'battery_wh' => fake()->optional()->randomElement([400, 500, 625, 750]),
            'range_km' => fake()->optional()->numberBetween(40, 120),
        ];
    }
}
