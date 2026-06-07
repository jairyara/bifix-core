<?php

declare(strict_types=1);

namespace App\Http\Resources;

use App\Models\BikeModel;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * @mixin BikeModel
 */
class BikeModelResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'name' => $this->name,
            'slug' => $this->slug,
            'year' => $this->year,
            'frame_type' => $this->frame_type,
            'motor_brand' => $this->motor_brand,
            'battery_wh' => $this->battery_wh,
            'range_km' => $this->range_km,
            'brand' => new BrandResource($this->whenLoaded('brand')),
            'battery_type' => new BatteryTypeResource($this->whenLoaded('batteryType')),
        ];
    }
}
