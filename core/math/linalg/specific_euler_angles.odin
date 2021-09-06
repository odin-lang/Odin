package linalg

Euler_Angle_Order :: enum {
	// Tait-Bryan
	XYZ,
	XZY,
	YXZ,
	YZX,
	ZXY,
	ZYX,

	// Proper Euler
	XYX,
	XZX,
	YXY,
	YZY,
	ZXZ,
	ZYZ,
}


quaternion_from_euler_angles       :: proc{quaternion_from_euler_angles_f16,       quaternion_from_euler_angles_f32,       quaternion_from_euler_angles_f64}
quaternion_from_euler_angle_x      :: proc{quaternion_from_euler_angle_x_f16,      quaternion_from_euler_angle_x_f32,      quaternion_from_euler_angle_x_f64}
quaternion_from_euler_angle_y      :: proc{quaternion_from_euler_angle_y_f16,      quaternion_from_euler_angle_y_f32,      quaternion_from_euler_angle_y_f64}
quaternion_from_euler_angle_z      :: proc{quaternion_from_euler_angle_z_f16,      quaternion_from_euler_angle_z_f32,      quaternion_from_euler_angle_z_f64}
quaternion_from_pitch_yaw_roll     :: proc{quaternion_from_pitch_yaw_roll_f16,     quaternion_from_pitch_yaw_roll_f32,     quaternion_from_pitch_yaw_roll_f64}

euler_angles_from_quaternion       :: proc{euler_angles_from_quaternion_f16,       euler_angles_from_quaternion_f32,       euler_angles_from_quaternion_f64}
euler_angles_xyz_from_quaternion   :: proc{euler_angles_xyz_from_quaternion_f16,   euler_angles_xyz_from_quaternion_f32,   euler_angles_xyz_from_quaternion_f64}
euler_angles_yxz_from_quaternion   :: proc{euler_angles_yxz_from_quaternion_f16,   euler_angles_yxz_from_quaternion_f32,   euler_angles_yxz_from_quaternion_f64}
euler_angles_xzx_from_quaternion   :: proc{euler_angles_xzx_from_quaternion_f16,   euler_angles_xzx_from_quaternion_f32,   euler_angles_xzx_from_quaternion_f64}
euler_angles_xyx_from_quaternion   :: proc{euler_angles_xyx_from_quaternion_f16,   euler_angles_xyx_from_quaternion_f32,   euler_angles_xyx_from_quaternion_f64}
euler_angles_yxy_from_quaternion   :: proc{euler_angles_yxy_from_quaternion_f16,   euler_angles_yxy_from_quaternion_f32,   euler_angles_yxy_from_quaternion_f64}
euler_angles_yzy_from_quaternion   :: proc{euler_angles_yzy_from_quaternion_f16,   euler_angles_yzy_from_quaternion_f32,   euler_angles_yzy_from_quaternion_f64}
euler_angles_zyz_from_quaternion   :: proc{euler_angles_zyz_from_quaternion_f16,   euler_angles_zyz_from_quaternion_f32,   euler_angles_zyz_from_quaternion_f64}
euler_angles_zxz_from_quaternion   :: proc{euler_angles_zxz_from_quaternion_f16,   euler_angles_zxz_from_quaternion_f32,   euler_angles_zxz_from_quaternion_f64}
euler_angles_xzy_from_quaternion   :: proc{euler_angles_xzy_from_quaternion_f16,   euler_angles_xzy_from_quaternion_f32,   euler_angles_xzy_from_quaternion_f64}
euler_angles_yzx_from_quaternion   :: proc{euler_angles_yzx_from_quaternion_f16,   euler_angles_yzx_from_quaternion_f32,   euler_angles_yzx_from_quaternion_f64}
euler_angles_zyx_from_quaternion   :: proc{euler_angles_zyx_from_quaternion_f16,   euler_angles_zyx_from_quaternion_f32,   euler_angles_zyx_from_quaternion_f64}
euler_angles_zxy_from_quaternion   :: proc{euler_angles_zxy_from_quaternion_f16,   euler_angles_zxy_from_quaternion_f32,   euler_angles_zxy_from_quaternion_f64}

roll_from_quaternion               :: proc{roll_from_quaternion_f16,               roll_from_quaternion_f32,               roll_from_quaternion_f64}
pitch_from_quaternion              :: proc{pitch_from_quaternion_f16,              pitch_from_quaternion_f32,              pitch_from_quaternion_f64}
yaw_from_quaternion                :: proc{yaw_from_quaternion_f16,                yaw_from_quaternion_f32,                yaw_from_quaternion_f64}
pitch_yaw_roll_from_quaternion     :: proc{pitch_yaw_roll_from_quaternion_f16,     pitch_yaw_roll_from_quaternion_f32,     pitch_yaw_roll_from_quaternion_f64}

matrix3_from_euler_angles          :: proc{matrix3_from_euler_angles_f16,          matrix3_from_euler_angles_f32,          matrix3_from_euler_angles_f64}
matrix3_from_euler_angle_x         :: proc{matrix3_from_euler_angle_x_f16,         matrix3_from_euler_angle_x_f32,         matrix3_from_euler_angle_x_f64}
matrix3_from_euler_angle_y         :: proc{matrix3_from_euler_angle_y_f16,         matrix3_from_euler_angle_y_f32,         matrix3_from_euler_angle_y_f64}
matrix3_from_euler_angle_z         :: proc{matrix3_from_euler_angle_z_f16,         matrix3_from_euler_angle_z_f32,         matrix3_from_euler_angle_z_f64}
matrix3_from_derived_euler_angle_x :: proc{matrix3_from_derived_euler_angle_x_f16, matrix3_from_derived_euler_angle_x_f32, matrix3_from_derived_euler_angle_x_f64}
matrix3_from_derived_euler_angle_y :: proc{matrix3_from_derived_euler_angle_y_f16, matrix3_from_derived_euler_angle_y_f32, matrix3_from_derived_euler_angle_y_f64}
matrix3_from_derived_euler_angle_z :: proc{matrix3_from_derived_euler_angle_z_f16, matrix3_from_derived_euler_angle_z_f32, matrix3_from_derived_euler_angle_z_f64}
matrix3_from_euler_angles_xy       :: proc{matrix3_from_euler_angles_xy_f16,       matrix3_from_euler_angles_xy_f32,       matrix3_from_euler_angles_xy_f64}
matrix3_from_euler_angles_yx       :: proc{matrix3_from_euler_angles_yx_f16,       matrix3_from_euler_angles_yx_f32,       matrix3_from_euler_angles_yx_f64}
matrix3_from_euler_angles_xz       :: proc{matrix3_from_euler_angles_xz_f16,       matrix3_from_euler_angles_xz_f32,       matrix3_from_euler_angles_xz_f64}
matrix3_from_euler_angles_zx       :: proc{matrix3_from_euler_angles_zx_f16,       matrix3_from_euler_angles_zx_f32,       matrix3_from_euler_angles_zx_f64}
matrix3_from_euler_angles_yz       :: proc{matrix3_from_euler_angles_yz_f16,       matrix3_from_euler_angles_yz_f32,       matrix3_from_euler_angles_yz_f64}
matrix3_from_euler_angles_zy       :: proc{matrix3_from_euler_angles_zy_f16,       matrix3_from_euler_angles_zy_f32,       matrix3_from_euler_angles_zy_f64}
matrix3_from_euler_angles_xyz      :: proc{matrix3_from_euler_angles_xyz_f16,      matrix3_from_euler_angles_xyz_f32,      matrix3_from_euler_angles_xyz_f64}
matrix3_from_euler_angles_yxz      :: proc{matrix3_from_euler_angles_yxz_f16,      matrix3_from_euler_angles_yxz_f32,      matrix3_from_euler_angles_yxz_f64}
matrix3_from_euler_angles_xzx      :: proc{matrix3_from_euler_angles_xzx_f16,      matrix3_from_euler_angles_xzx_f32,      matrix3_from_euler_angles_xzx_f64}
matrix3_from_euler_angles_xyx      :: proc{matrix3_from_euler_angles_xyx_f16,      matrix3_from_euler_angles_xyx_f32,      matrix3_from_euler_angles_xyx_f64}
matrix3_from_euler_angles_yxy      :: proc{matrix3_from_euler_angles_yxy_f16,      matrix3_from_euler_angles_yxy_f32,      matrix3_from_euler_angles_yxy_f64}
matrix3_from_euler_angles_yzy      :: proc{matrix3_from_euler_angles_yzy_f16,      matrix3_from_euler_angles_yzy_f32,      matrix3_from_euler_angles_yzy_f64}
matrix3_from_euler_angles_zyz      :: proc{matrix3_from_euler_angles_zyz_f16,      matrix3_from_euler_angles_zyz_f32,      matrix3_from_euler_angles_zyz_f64}
matrix3_from_euler_angles_zxz      :: proc{matrix3_from_euler_angles_zxz_f16,      matrix3_from_euler_angles_zxz_f32,      matrix3_from_euler_angles_zxz_f64}
matrix3_from_euler_angles_xzy      :: proc{matrix3_from_euler_angles_xzy_f16,      matrix3_from_euler_angles_xzy_f32,      matrix3_from_euler_angles_xzy_f64}
matrix3_from_euler_angles_yzx      :: proc{matrix3_from_euler_angles_yzx_f16,      matrix3_from_euler_angles_yzx_f32,      matrix3_from_euler_angles_yzx_f64}
matrix3_from_euler_angles_zyx      :: proc{matrix3_from_euler_angles_zyx_f16,      matrix3_from_euler_angles_zyx_f32,      matrix3_from_euler_angles_zyx_f64}
matrix3_from_euler_angles_zxy      :: proc{matrix3_from_euler_angles_zxy_f16,      matrix3_from_euler_angles_zxy_f32,      matrix3_from_euler_angles_zxy_f64}
matrix3_from_yaw_pitch_roll        :: proc{matrix3_from_yaw_pitch_roll_f16,        matrix3_from_yaw_pitch_roll_f32,        matrix3_from_yaw_pitch_roll_f64}

euler_angles_from_matrix3          :: proc{euler_angles_from_matrix3_f16,          euler_angles_from_matrix3_f32,          euler_angles_from_matrix3_f64}
euler_angles_xyz_from_matrix3      :: proc{euler_angles_xyz_from_matrix3_f16,      euler_angles_xyz_from_matrix3_f32,      euler_angles_xyz_from_matrix3_f64}
euler_angles_yxz_from_matrix3      :: proc{euler_angles_yxz_from_matrix3_f16,      euler_angles_yxz_from_matrix3_f32,      euler_angles_yxz_from_matrix3_f64}
euler_angles_xzx_from_matrix3      :: proc{euler_angles_xzx_from_matrix3_f16,      euler_angles_xzx_from_matrix3_f32,      euler_angles_xzx_from_matrix3_f64}
euler_angles_xyx_from_matrix3      :: proc{euler_angles_xyx_from_matrix3_f16,      euler_angles_xyx_from_matrix3_f32,      euler_angles_xyx_from_matrix3_f64}
euler_angles_yxy_from_matrix3      :: proc{euler_angles_yxy_from_matrix3_f16,      euler_angles_yxy_from_matrix3_f32,      euler_angles_yxy_from_matrix3_f64}
euler_angles_yzy_from_matrix3      :: proc{euler_angles_yzy_from_matrix3_f16,      euler_angles_yzy_from_matrix3_f32,      euler_angles_yzy_from_matrix3_f64}
euler_angles_zyz_from_matrix3      :: proc{euler_angles_zyz_from_matrix3_f16,      euler_angles_zyz_from_matrix3_f32,      euler_angles_zyz_from_matrix3_f64}
euler_angles_zxz_from_matrix3      :: proc{euler_angles_zxz_from_matrix3_f16,      euler_angles_zxz_from_matrix3_f32,      euler_angles_zxz_from_matrix3_f64}
euler_angles_xzy_from_matrix3      :: proc{euler_angles_xzy_from_matrix3_f16,      euler_angles_xzy_from_matrix3_f32,      euler_angles_xzy_from_matrix3_f64}
euler_angles_yzx_from_matrix3      :: proc{euler_angles_yzx_from_matrix3_f16,      euler_angles_yzx_from_matrix3_f32,      euler_angles_yzx_from_matrix3_f64}
euler_angles_zyx_from_matrix3      :: proc{euler_angles_zyx_from_matrix3_f16,      euler_angles_zyx_from_matrix3_f32,      euler_angles_zyx_from_matrix3_f64}
euler_angles_zxy_from_matrix3      :: proc{euler_angles_zxy_from_matrix3_f16,      euler_angles_zxy_from_matrix3_f32,      euler_angles_zxy_from_matrix3_f64}

matrix4_from_euler_angles          :: proc{matrix4_from_euler_angles_f16,          matrix4_from_euler_angles_f32,          matrix4_from_euler_angles_f64}
matrix4_from_euler_angle_x         :: proc{matrix4_from_euler_angle_x_f16,         matrix4_from_euler_angle_x_f32,         matrix4_from_euler_angle_x_f64}
matrix4_from_euler_angle_y         :: proc{matrix4_from_euler_angle_y_f16,         matrix4_from_euler_angle_y_f32,         matrix4_from_euler_angle_y_f64}
matrix4_from_euler_angle_z         :: proc{matrix4_from_euler_angle_z_f16,         matrix4_from_euler_angle_z_f32,         matrix4_from_euler_angle_z_f64}
matrix4_from_derived_euler_angle_x :: proc{matrix4_from_derived_euler_angle_x_f16, matrix4_from_derived_euler_angle_x_f32, matrix4_from_derived_euler_angle_x_f64}
matrix4_from_derived_euler_angle_y :: proc{matrix4_from_derived_euler_angle_y_f16, matrix4_from_derived_euler_angle_y_f32, matrix4_from_derived_euler_angle_y_f64}
matrix4_from_derived_euler_angle_z :: proc{matrix4_from_derived_euler_angle_z_f16, matrix4_from_derived_euler_angle_z_f32, matrix4_from_derived_euler_angle_z_f64}
matrix4_from_euler_angles_xy       :: proc{matrix4_from_euler_angles_xy_f16,       matrix4_from_euler_angles_xy_f32,       matrix4_from_euler_angles_xy_f64}
matrix4_from_euler_angles_yx       :: proc{matrix4_from_euler_angles_yx_f16,       matrix4_from_euler_angles_yx_f32,       matrix4_from_euler_angles_yx_f64}
matrix4_from_euler_angles_xz       :: proc{matrix4_from_euler_angles_xz_f16,       matrix4_from_euler_angles_xz_f32,       matrix4_from_euler_angles_xz_f64}
matrix4_from_euler_angles_zx       :: proc{matrix4_from_euler_angles_zx_f16,       matrix4_from_euler_angles_zx_f32,       matrix4_from_euler_angles_zx_f64}
matrix4_from_euler_angles_yz       :: proc{matrix4_from_euler_angles_yz_f16,       matrix4_from_euler_angles_yz_f32,       matrix4_from_euler_angles_yz_f64}
matrix4_from_euler_angles_zy       :: proc{matrix4_from_euler_angles_zy_f16,       matrix4_from_euler_angles_zy_f32,       matrix4_from_euler_angles_zy_f64}
matrix4_from_euler_angles_xyz      :: proc{matrix4_from_euler_angles_xyz_f16,      matrix4_from_euler_angles_xyz_f32,      matrix4_from_euler_angles_xyz_f64}
matrix4_from_euler_angles_yxz      :: proc{matrix4_from_euler_angles_yxz_f16,      matrix4_from_euler_angles_yxz_f32,      matrix4_from_euler_angles_yxz_f64}
matrix4_from_euler_angles_xzx      :: proc{matrix4_from_euler_angles_xzx_f16,      matrix4_from_euler_angles_xzx_f32,      matrix4_from_euler_angles_xzx_f64}
matrix4_from_euler_angles_xyx      :: proc{matrix4_from_euler_angles_xyx_f16,      matrix4_from_euler_angles_xyx_f32,      matrix4_from_euler_angles_xyx_f64}
matrix4_from_euler_angles_yxy      :: proc{matrix4_from_euler_angles_yxy_f16,      matrix4_from_euler_angles_yxy_f32,      matrix4_from_euler_angles_yxy_f64}
matrix4_from_euler_angles_yzy      :: proc{matrix4_from_euler_angles_yzy_f16,      matrix4_from_euler_angles_yzy_f32,      matrix4_from_euler_angles_yzy_f64}
matrix4_from_euler_angles_zyz      :: proc{matrix4_from_euler_angles_zyz_f16,      matrix4_from_euler_angles_zyz_f32,      matrix4_from_euler_angles_zyz_f64}
matrix4_from_euler_angles_zxz      :: proc{matrix4_from_euler_angles_zxz_f16,      matrix4_from_euler_angles_zxz_f32,      matrix4_from_euler_angles_zxz_f64}
matrix4_from_euler_angles_xzy      :: proc{matrix4_from_euler_angles_xzy_f16,      matrix4_from_euler_angles_xzy_f32,      matrix4_from_euler_angles_xzy_f64}
matrix4_from_euler_angles_yzx      :: proc{matrix4_from_euler_angles_yzx_f16,      matrix4_from_euler_angles_yzx_f32,      matrix4_from_euler_angles_yzx_f64}
matrix4_from_euler_angles_zyx      :: proc{matrix4_from_euler_angles_zyx_f16,      matrix4_from_euler_angles_zyx_f32,      matrix4_from_euler_angles_zyx_f64}
matrix4_from_euler_angles_zxy      :: proc{matrix4_from_euler_angles_zxy_f16,      matrix4_from_euler_angles_zxy_f32,      matrix4_from_euler_angles_zxy_f64}
matrix4_from_yaw_pitch_roll        :: proc{matrix4_from_yaw_pitch_roll_f16,        matrix4_from_yaw_pitch_roll_f32,        matrix4_from_yaw_pitch_roll_f64}

euler_angles_from_matrix4          :: proc{euler_angles_from_matrix4_f16,          euler_angles_from_matrix4_f32,          euler_angles_from_matrix4_f64}
euler_angles_xyz_from_matrix4      :: proc{euler_angles_xyz_from_matrix4_f16,      euler_angles_xyz_from_matrix4_f32,      euler_angles_xyz_from_matrix4_f64}
euler_angles_yxz_from_matrix4      :: proc{euler_angles_yxz_from_matrix4_f16,      euler_angles_yxz_from_matrix4_f32,      euler_angles_yxz_from_matrix4_f64}
euler_angles_xzx_from_matrix4      :: proc{euler_angles_xzx_from_matrix4_f16,      euler_angles_xzx_from_matrix4_f32,      euler_angles_xzx_from_matrix4_f64}
euler_angles_xyx_from_matrix4      :: proc{euler_angles_xyx_from_matrix4_f16,      euler_angles_xyx_from_matrix4_f32,      euler_angles_xyx_from_matrix4_f64}
euler_angles_yxy_from_matrix4      :: proc{euler_angles_yxy_from_matrix4_f16,      euler_angles_yxy_from_matrix4_f32,      euler_angles_yxy_from_matrix4_f64}
euler_angles_yzy_from_matrix4      :: proc{euler_angles_yzy_from_matrix4_f16,      euler_angles_yzy_from_matrix4_f32,      euler_angles_yzy_from_matrix4_f64}
euler_angles_zyz_from_matrix4      :: proc{euler_angles_zyz_from_matrix4_f16,      euler_angles_zyz_from_matrix4_f32,      euler_angles_zyz_from_matrix4_f64}
euler_angles_zxz_from_matrix4      :: proc{euler_angles_zxz_from_matrix4_f16,      euler_angles_zxz_from_matrix4_f32,      euler_angles_zxz_from_matrix4_f64}
euler_angles_xzy_from_matrix4      :: proc{euler_angles_xzy_from_matrix4_f16,      euler_angles_xzy_from_matrix4_f32,      euler_angles_xzy_from_matrix4_f64}
euler_angles_yzx_from_matrix4      :: proc{euler_angles_yzx_from_matrix4_f16,      euler_angles_yzx_from_matrix4_f32,      euler_angles_yzx_from_matrix4_f64}
euler_angles_zyx_from_matrix4      :: proc{euler_angles_zyx_from_matrix4_f16,      euler_angles_zyx_from_matrix4_f32,      euler_angles_zyx_from_matrix4_f64}
euler_angles_zxy_from_matrix4      :: proc{euler_angles_zxy_from_matrix4_f16,      euler_angles_zxy_from_matrix4_f32,      euler_angles_zxy_from_matrix4_f64}
