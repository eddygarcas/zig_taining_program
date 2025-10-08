
typedef struct {
    float x;
    float y;
    float z;
} vec3;
float vec_lenght(vec3 v) {
    return sqrt(v.x * v.x + v.y * v.y + v.z * v.z);
}