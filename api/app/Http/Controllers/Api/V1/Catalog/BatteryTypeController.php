<?php

declare(strict_types=1);

namespace App\Http\Controllers\Api\V1\Catalog;

use App\Http\Controllers\Controller;
use App\Http\Resources\BatteryTypeResource;
use App\Models\BatteryType;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;

class BatteryTypeController extends Controller
{
    public function index(): AnonymousResourceCollection
    {
        $batteryTypes = BatteryType::query()
            ->where('is_active', true)
            ->orderBy('name')
            ->get();

        return BatteryTypeResource::collection($batteryTypes);
    }
}
