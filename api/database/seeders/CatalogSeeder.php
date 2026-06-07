<?php

namespace Database\Seeders;

use App\Models\BatteryType;
use App\Models\BikeModel;
use App\Models\Brand;
use Illuminate\Database\Seeder;
use Illuminate\Support\Str;

class CatalogSeeder extends Seeder
{
    /**
     * @return array<string, list<array<string, mixed>>>
     */
    public static function catalog(): array
    {
        return [
            'giant' => [
                [
                    'name' => 'Explore E+ 2',
                    'slug' => 'explore-e-2',
                    'year' => 2024,
                    'frame_type' => 'city',
                    'battery_wh' => 500,
                    'range_km' => 80,
                ],
                [
                    'name' => 'Trance X E+ 3',
                    'slug' => 'trance-x-e-3',
                    'year' => 2023,
                    'frame_type' => 'mtb',
                    'battery_wh' => 625,
                    'range_km' => 70,
                ],
            ],
            'trek' => [
                [
                    'name' => 'Domane+ SLR 6',
                    'slug' => 'domane-slr-6',
                    'year' => 2024,
                    'frame_type' => 'road',
                    'battery_wh' => 360,
                    'range_km' => 90,
                ],
                [
                    'name' => 'Powerfly 5',
                    'slug' => 'powerfly-5',
                    'year' => 2023,
                    'frame_type' => 'mtb',
                    'battery_wh' => 625,
                    'range_km' => 65,
                ],
            ],
            'specialized' => [
                [
                    'name' => 'Turbo Vado 4.0',
                    'slug' => 'turbo-vado-4-0',
                    'year' => 2024,
                    'frame_type' => 'city',
                    'battery_wh' => 710,
                    'range_km' => 120,
                ],
            ],
        ];
    }

    public function run(): void
    {
        $this->call(BatteryTypeSeeder::class);

        $lithium = BatteryType::query()->where('slug', 'lithium')->firstOrFail();

        foreach (self::catalog() as $brandSlug => $models) {
            $brand = Brand::query()->updateOrCreate(
                ['slug' => $brandSlug],
                ['name' => Str::title(str_replace('-', ' ', $brandSlug))],
            );

            foreach ($models as $model) {
                BikeModel::query()->updateOrCreate(
                    [
                        'brand_id' => $brand->id,
                        'slug' => $model['slug'],
                    ],
                    [
                        ...$model,
                        'battery_type_id' => $lithium->id,
                        'motor_brand' => 'Bosch',
                    ],
                );
            }
        }
    }
}
