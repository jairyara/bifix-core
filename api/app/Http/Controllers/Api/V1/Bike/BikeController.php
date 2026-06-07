<?php

declare(strict_types=1);

namespace App\Http\Controllers\Api\V1\Bike;

use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\Bike\StoreBikeRequest;
use App\Http\Requests\Api\V1\Bike\UpdateBikeRequest;
use App\Http\Resources\BikeResource;
use App\Models\Bike;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;

class BikeController extends Controller
{
    public function index(Request $request): AnonymousResourceCollection
    {
        $bikes = $request->user()
            ->bikes()
            ->with(['bikeModel.brand', 'bikeModel.batteryType'])
            ->latest()
            ->get();

        return BikeResource::collection($bikes);
    }

    public function store(StoreBikeRequest $request): JsonResponse
    {
        $bike = $request->user()->bikes()->create($request->validated());
        $bike->load(['bikeModel.brand', 'bikeModel.batteryType']);

        return response()->json([
            'data' => new BikeResource($bike),
        ], 201);
    }

    public function show(Bike $bike): JsonResponse
    {
        $bike->load(['bikeModel.brand', 'bikeModel.batteryType']);

        return response()->json([
            'data' => new BikeResource($bike),
        ]);
    }

    public function update(UpdateBikeRequest $request, Bike $bike): JsonResponse
    {
        $bike->update($request->validated());
        $bike->load(['bikeModel.brand', 'bikeModel.batteryType']);

        return response()->json([
            'data' => new BikeResource($bike),
        ]);
    }

    public function destroy(Bike $bike): JsonResponse
    {
        $bike->delete();

        return response()->json(null, 204);
    }
}
