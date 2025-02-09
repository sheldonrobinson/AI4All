#ifndef ENUMS_H
#define ENUMS_H

#ifdef __cplusplus
extern "C"
{
#endif

/// Possible capture errors
typedef enum AudioDeviceErrors
{
    /// No error
    noError = 0,
    /// The capture device has failed to initialize.
    initFailed = 1,
    /// The capture device has not yet been initialized.
    notInited = 2,
    /// Device not found
    deviceNotFound = 3,
    /// Failed to start the device.
    failedToStartDevice = 4,
	/// Failed to stop the device.
    failedToStopDevice = 5,
    /// Failed to initialize wav recording / playback / buffer.
    failedToInitialize = 6,
    /// Failed to start wav recording / playback.
    failedToStart = 7,
    /// Failed to initialize wav recording / playback.
    failedToStop = 8,
	/// Failed to initialize wav recording / playback.
    failedToAbort = 9,
    /// Invalid arguments while initializing wav recording.
    invalidArgs = 10,
    /// Failed to read from buffer
    failedToRead = 11,
    /// Failed to write to buffer
    failedToWrite = 12,

} AudioDeviceErrors_t;

typedef enum PCMFormat
{
    pcm_u8,
    pcm_s16,
    pcm_s24,
    pcm_s32,
    pcm_f32
} PCMFormatInternal_t;

#ifdef __cplusplus
}
#endif

#endif // ENUMS_H