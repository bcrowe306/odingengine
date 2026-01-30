import math



def lerp(a, b, t):
    return a + (b - a) * t

amount = 10
lifetime = 2.0
explosivity = 1.0 # 0.0 to 1.0

max_time = lifetime / amount
min_time = 0
particle_time_interval = lerp(max_time, min_time, explosivity)



print(f"Spawn particles every {particle_time_interval} seconds")