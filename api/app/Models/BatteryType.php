<?php

declare(strict_types=1);

namespace App\Models;

use Database\Factories\BatteryTypeFactory;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

#[Fillable(['name', 'slug', 'description', 'is_active'])]
class BatteryType extends Model
{
    /** @use HasFactory<BatteryTypeFactory> */
    use HasFactory;

    /**
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'is_active' => 'boolean',
        ];
    }

    /**
     * @return HasMany<BikeModel, $this>
     */
    public function bikeModels(): HasMany
    {
        return $this->hasMany(BikeModel::class);
    }
}
