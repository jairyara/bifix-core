<?php

declare(strict_types=1);

namespace App\Http\Controllers\Api\V1\Ride;

use App\Http\Controllers\Controller;
use App\Http\Requests\Api\V1\Ride\StoreRideRequest;
use App\Http\Requests\Api\V1\Ride\UpdateRideRequest;
use App\Http\Resources\RideResource;
use App\Models\Bike;
use App\Models\Ride;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Resources\Json\AnonymousResourceCollection;
use Illuminate\Support\Facades\DB;

class RideController extends Controller
{
    public function index(Bike $bike): AnonymousResourceCollection
    {
        $rides = $bike->rides()
            ->latest('started_at')
            ->latest()
            ->get();

        return RideResource::collection($rides);
    }

    public function store(StoreRideRequest $request, Bike $bike): JsonResponse
    {
        $ride = DB::transaction(function () use ($request, $bike) {
            $ride = $bike->rides()->create([
                ...$request->validated(),
                'user_id' => $request->user()->id,
            ]);

            $bike->increment('odometer_km', $ride->distance_km);

            return $ride;
        });

        return response()->json([
            'data' => new RideResource($ride),
        ], 201);
    }

    public function show(Bike $bike, Ride $ride): JsonResponse
    {
        return response()->json([
            'data' => new RideResource($ride),
        ]);
    }

    public function update(UpdateRideRequest $request, Bike $bike, Ride $ride): JsonResponse
    {
        DB::transaction(function () use ($request, $bike, $ride) {
            $previousDistance = $ride->distance_km;

            $ride->update($request->validated());

            if ($request->has('distance_km')) {
                $difference = $ride->distance_km - $previousDistance;

                if ($difference > 0) {
                    $bike->increment('odometer_km', $difference);
                } elseif ($difference < 0) {
                    $bike->decrement('odometer_km', min(abs($difference), $bike->odometer_km ?? 0));
                }
            }
        });

        return response()->json([
            'data' => new RideResource($ride->fresh()),
        ]);
    }

    public function destroy(Bike $bike, Ride $ride): JsonResponse
    {
        DB::transaction(function () use ($bike, $ride) {
            $bike->decrement('odometer_km', min($ride->distance_km, $bike->odometer_km ?? 0));
            $ride->delete();
        });

        return response()->json(null, 204);
    }
}
