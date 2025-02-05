package sdl3

import "core:c"

Sensor :: struct {}

SensorID :: distinct Uint32

STANDARD_GRAVITY :: 9.80665

SensorType :: enum c.int {
	INVALID = -1,    /**< Returned for an invalid sensor */
	UNKNOWN,         /**< Unknown sensor type */
	ACCEL,           /**< Accelerometer */
	GYRO,            /**< Gyroscope */
	ACCEL_L,         /**< Accelerometer for left Joy-Con controller and Wii nunchuk */
	GYRO_L,          /**< Gyroscope for left Joy-Con controller */
	ACCEL_R,         /**< Accelerometer for right Joy-Con controller */
	GYRO_R,          /**< Gyroscope for right Joy-Con controller */
}

@(default_calling_convention="c", link_prefix="SDL_", require_results)
foreign lib {
	GetSensors                    :: proc(count: ^c.int) -> [^]SensorID ---
	GetSensorNameForID            :: proc(instance_id: SensorID) -> cstring ---
	GetSensorTypeForID            :: proc(instance_id: SensorID) -> SensorType ---
	GetSensorNonPortableTypeForID :: proc(instance_id: SensorID) -> c.int ---
	OpenSensor                    :: proc(instance_id: SensorID) -> ^Sensor ---
	GetSensorFromID               :: proc(instance_id: SensorID) -> ^Sensor ---
	GetSensorProperties           :: proc(sensor: ^Sensor) -> PropertiesID ---
	GetSensorName                 :: proc(sensor: ^Sensor) -> cstring ---
	GetSensorType                 :: proc(sensor: ^Sensor) -> SensorType ---
	GetSensorNonPortableType      :: proc(sensor: ^Sensor) -> c.int ---
	GetSensorID                   :: proc(sensor: ^Sensor) -> SensorID ---
	GetSensorData                 :: proc(sensor: ^Sensor, data: [^]f32, num_values: c.int) -> bool ---
	CloseSensor                   :: proc(sensor: ^Sensor) ---
	UpdateSensors                 :: proc() ---
}