from datetime import datetime

from pydantic import BaseModel, EmailStr


class SignupRequest(BaseModel):
    first_name: str
    last_name: str
    email: EmailStr
    password: str
    roles: list[str] = ["FAN"]


class LoginRequest(BaseModel):
    email: EmailStr
    password: str


class UserResponse(BaseModel):
    id: int
    email: EmailStr
    roles: list[str]
    is_active: bool
    created_at: datetime
    person_id: int | None = None


class PersonResponse(BaseModel):
    id: int
    first_name: str
    last_name: str


class UserWithPersonResponse(BaseModel):
    user: UserResponse
    person: PersonResponse | None = None


class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user: UserResponse
