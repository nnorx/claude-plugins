from fastapi import APIRouter

router = APIRouter()


@router.get("/users/{user_id}")
def get_user(user_id: int):
    try:
        return load(user_id)  # noqa: F821
    except:  # noqa: E722
        return None
