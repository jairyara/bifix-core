<?php

declare(strict_types=1);

namespace App\Models;

use Database\Factories\BikeModelFactory;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

#[Fillable([
    'brand_id',
    'battery_type_id',
    'name',
    'slug',
    'year',
    'frame_type',
    'motor_brand',
    'battery_wh',
    'range_km',
])]
class BikeModel extends Model
{
    /** @use HasFactory<BikeModelFactory> */
    use HasFactory;

    /**
     * @return BelongsTo<Brand, $this>
     */
    public function brand(): BelongsTo
    {
        return $this->belongsTo(Brand::class);
    }

    /**
     * @return BelongsTo<BatteryType, $this>
     */
    public function batteryType(): BelongsTo
    {
        return $this->belongsTo(BatteryType::class);
    }

    /**
     * @return HasMany<Bike, $this>
     */
    public function bikes(): HasMany
    {
        return $this->hasMany(Bike::class);
    }
}
