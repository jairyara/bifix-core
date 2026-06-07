<?php

declare(strict_types=1);

namespace App\Models;

use Database\Factories\RideFactory;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

#[Fillable([
    'user_id',
    'bike_id',
    'distance_km',
    'started_at',
    'ended_at',
    'notes',
])]
class Ride extends Model
{
    /** @use HasFactory<RideFactory> */
    use HasFactory;

    /**
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'started_at' => 'datetime',
            'ended_at' => 'datetime',
        ];
    }

    /**
     * @return BelongsTo<User, $this>
     */
    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    /**
     * @return BelongsTo<Bike, $this>
     */
    public function bike(): BelongsTo
    {
        return $this->belongsTo(Bike::class);
    }

    public function resolveRouteBinding(mixed $value, $field = null): static
    {
        /** @var Bike $bike */
        $bike = request()->route('bike');

        return $this->where($field ?? $this->getRouteKeyName(), $value)
            ->where('bike_id', $bike->id)
            ->where('user_id', auth()->id())
            ->firstOrFail();
    }
}
