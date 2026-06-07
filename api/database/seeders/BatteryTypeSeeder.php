<?php

namespace Database\Seeders;

use App\Models\BatteryType;
use Illuminate\Database\Seeder;

class BatteryTypeSeeder extends Seeder
{
    public function run(): void
    {
        $types = [
            [
                'name' => 'Lead',
                'slug' => 'lead',
                'description' => 'Lead-acid batteries (legacy e-bikes)',
            ],
            [
                'name' => 'Lithium',
                'slug' => 'lithium',
                'description' => 'Lithium-ion batteries',
            ],
        ];

        foreach ($types as $type) {
            BatteryType::query()->updateOrCreate(
                ['slug' => $type['slug']],
                $type,
            );
        }
    }
}
