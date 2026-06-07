<?php

declare(strict_types=1);

namespace App\Http\Resources;

use App\Models\Bike;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * @mixin Bike
 */
class BikeResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'serial_number' => $this->serial_number,
            'frame_number' => $this->frame_number,
            'nickname' => $this->nickname,
            'color' => $this->color,
            'odometer_km' => $this->odometer_km,
            'purchased_at' => $this->purchased_at?->toDateString(),
            'model' => new BikeModelResource($this->whenLoaded('bikeModel')),
            'created_at' => $this->created_at?->toIso8601String(),
            'updated_at' => $this->updated_at?->toIso8601String(),
        ];
    }
}
