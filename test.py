from enum import Enum

class ComponentType(Enum):
    TRANFORM=0
    RECTANGLE=1
    CIRCLE=2
    RENDER=3
    UPDATE=4

class Vec2:
    def __init__(self, x: float = 0.0, y: float = 0.0):
        self.x = x
        self.y = y

    def __repr__(self):
        return f"Vec2({self.x}, {self.y})"
    def __str__(self) -> str:
        return f"Vec2({self.x}, {self.y})"

    def __add__(self, other):
        return Vec2(self.x + other.x, self.y + other.y)
    
    def __sub__(self, other):
        return Vec2(self.x - other.x, self.y - other.y)
    
    def __mul__(self, scalar: float):
        return Vec2(self.x * scalar, self.y * scalar)
    
    def __truediv__(self, scalar: float):
        return Vec2(self.x / scalar, self.y / scalar)
    
    def distance_to(self, other) -> float:
        return ((self.x - other.x) ** 2 + (self.y - other.y) ** 2) ** 0.5

class Vec3:
    def __init__(self, x: float = 0.0, y: float = 0.0, z: float = 0.0):
        self.x = x
        self.y = y
        self.z = z

    def __repr__(self):
        return f"Vec3({self.x}, {self.y}, {self.z})"
    def __str__(self) -> str:
        return f"Vec3({self.x}, {self.y}, {self.z})"
    
    def __add__(self, other):
        return Vec3(self.x + other.x, self.y + other.y, self.z + other.z)
    
    def __sub__(self, other):
        return Vec3(self.x - other.x, self.y - other.y, self.z - other.z)
    
    def __mul__(self, scalar: float):
        return Vec3(self.x * scalar, self.y * scalar, self.z * scalar)
    
    def __truediv__(self, scalar: float):
        return Vec3(self.x / scalar, self.y / scalar, self.z / scalar)
    
    def distance_to(self, other) -> float:
        return ((self.x - other.x) ** 2 + (self.y - other.y) ** 2 + (self.z - other.z) ** 2) ** 0.5

class Vec4:
    def __init__(self, x: float = 0.0, y: float = 0.0, z: float = 0.0, w: float = 0.0):
        self.x = x
        self.y = y
        self.z = z
        self.w = w

    def __repr__(self):
        return f"Vec4({self.x}, {self.y}, {self.z}, {self.w})"
    def __str__(self) -> str:
        return f"Vec4({self.x}, {self.y}, {self.z}, {self.w})"
    
    def __add__(self, other):
        return Vec4(self.x + other.x, self.y + other.y, self.z + other.z, self.w + other.w)
    
    def __sub__(self, other):
        return Vec4(self.x - other.x, self.y - other.y, self.z - other.z, self.w - other.w)
    
    def __mul__(self, scalar: float):
        return Vec4(self.x * scalar, self.y * scalar, self.z * scalar, self.w * scalar)
    
    def __truediv__(self, scalar: float):
        return Vec4(self.x / scalar, self.y / scalar, self.z / scalar, self.w / scalar)

class Color:
    def __init__(self, r: int = 255, g: int = 255, b: int = 255, a: int = 255):
        self.r = r
        self.g = g
        self.b = b
        self.a = a

    def __repr__(self):
        return f"Color({self.r}, {self.g}, {self.b}, {self.a})"
    def __str__(self) -> str:
        return f"Color({self.r}, {self.g}, {self.b}, {self.a})"

    def to_tuple(self):
        return (self.r, self.g, self.b, self.a)

    @staticmethod
    def from_tuple(t: tuple):
        return Color(t[0], t[1], t[2], t[3])

    def to_units(self):
        return (self.r / 255.0, self.g / 255.0, self.b / 255.0, self.a / 255.0)

    @staticmethod
    def from_units(t: tuple):
        return Color(int(t[0] * 255), int(t[1] * 255), int(t[2] * 255), int(t[3] * 255))

    def to_hex(self) -> str:
        return f"#{self.r:02X}{self.g:02X}{self.b:02X}{self.a:02X}"

    @staticmethod
    def from_hex(hex_str: str):
        hex_str = hex_str.lstrip('#')
        if len(hex_str) == 8:
            r = int(hex_str[0:2], 16)
            g = int(hex_str[2:4], 16)
            b = int(hex_str[4:6], 16)
            a = int(hex_str[6:8], 16)
            return Color(r, g, b, a)
        elif len(hex_str) == 6:
            r = int(hex_str[0:2], 16)
            g = int(hex_str[2:4], 16)
            b = int(hex_str[4:6], 16)
            return Color(r, g, b, 255)
        else:
            raise ValueError("Hex string must be in format RRGGBBAA or RRGGBB")


class Entity:
    COUNT: int = 0

    def __init__(self, name: str = "Entity"):
        self.name = name
        self.id = Entity.COUNT
        self.components: dict[str, Component] = {}
        Entity.COUNT += 1



class Component:
    COMPONENT_COUNT: int = 0
    def __init__(self, entity_id: int, name: str = "Component"):
        if entity_id is None:
            raise ValueError("Component must be associated with a valid entity_id")
        if name == "Component":
            name = f"{self.__class__.__name__}_{entity_id}"
        self.entity_id = entity_id
        self.id = Component.COMPONENT_COUNT
        Component.COMPONENT_COUNT += 1
        self.name = name
        self.type: ComponentType


class TransformComponent(Component):
    def __init__(self, name:str, entity_id: int, position: Vec2 = Vec2(), scale: Vec2 = Vec2(1.0, 1.0), rotation: float = 0.0, origin: Vec2 = Vec2()):
        super().__init__(entity_id)
        self.position: Vec2 = position
        self.scale: Vec2 = scale
        self.rotation: float = rotation
        self.origin: Vec2 = origin
        self.type = ComponentType.TRANFORM

class Rectangle(Component):
    def __init__(self, name:str, entity_id: int, size: Vec2 = Vec2(10.0, 10.0), color: Color = Color()):
        super().__init__(entity_id)
        self.size: Vec2 = size
        self.color: Color = color
        self.type = ComponentType.RECTANGLE

class Circle(Component):
    def __init__(self, name:str, entity_id: int, radius: float = 10.0, color: Color = Color()):
        super().__init__(entity_id)
        self.radius: float = radius
        self.color: Color = color
        self.type = ComponentType.CIRCLE


class RenderComponent(Component):
    def __init__(self, name:str, entity_id: int, visible: bool = True, layer: str = "Default"):
        super().__init__(entity_id)
        self.visible: bool = visible
        self.layer: str = layer
        self.type = ComponentType.RENDER

    def draw(self):
        pass  # Placeholder for draw logic

class UpdateComponent(Component):
    def __init__(self, name:str, entity_id: int):
        super().__init__(entity_id)
        self.enabled: bool = True
        self.type = ComponentType.UPDATE

    def update(self, delta_time: float):
        pass  # Placeholder for update logic

player = Entity("Player")
player_transform = TransformComponent("PlayerTransform", player.id, position=Vec2(100.0, 150.0), scale=Vec2(1.0, 1.0), rotation=0.0, origin=Vec2(25.0, 25.0))
player_rectangle = Rectangle("PlayerRectangle", player.id, size=Vec2(50.0, 50.0), color=Color(0, 255, 0, 255))
player_update = UpdateComponent("PlayerUpdate", player.id)
player_render = RenderComponent("PlayerRender", player.id, visible=True, layer="Default")


class EntityManager:
    def __init__(self):
        self.entities: list[Entity] = []
        self.components: list[list[Component]] = []
        for _ in ComponentType:
            self.components.append([])

    def get_entity(self, entity_id: int) -> Entity | None:
        for entity in self.entities:
            if entity.id == entity_id:
                return entity
        return None
    
    def add_entity(self, entity: Entity):
        self.entities.append(entity)


    def remove_entity(self, entity_id: int):
        self.entities = [e for e in self.entities if e.id != entity_id]

    def get_component(self, component_type: ComponentType, component_id: int) -> Component | None:
        if component_type.value >= len(self.components):
            return None
        for component in self.components[component_type.value]:
            if component.id == component_id:
                return component
        return None
    
    def get_components_of_type(self, types: list[ComponentType], entity_id: int = -1) -> list[Component]:
        results = []
        for t in types:
            for component in self.components[t.value]:
                if entity_id == -1 or component.entity_id == entity_id:
                    results.append(component)
        return results
    
    def get_components_of_entity(self, entity_id: int) -> list[Component]:
        results = []
        for comp_list in self.components:
            for component in comp_list:
                if component.entity_id == entity_id:
                    results.append(component)
        return results
    
    def add_component(self, entity_id: int, component: Component):
        if component.type.value >= len(self.components):
            return
        self.components[component.type.value].append(component)
        entity = self.get_entity(entity_id)
        if entity:
            entity.components[component.name] = component


entity_manager = EntityManager()

entity_manager.add_entity(player)
