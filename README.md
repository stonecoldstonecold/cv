# face-id

Розпізнавання людей із заданої групи за фото (MTCNN + FaceNet embeddings), запуск у Docker.

## Структура даних

```
data/
  people/            # база відомих людей (5–20 фото на людину)
    Олена/1.jpg 2.jpg ...
    Іван/1.jpg ...
  test/              # необов'язково: окремі фото для оцінки точності
    Олена/a.jpg ...
  queries/           # фото, які треба розпізнати
  models/            # тут зберігається embeddings.pkl
  output/            # results.csv, identify_diagnostics.csv
```

Ім'я папки в `people/` = ім'я людини. Loader читає jpg/jpeg/png/bmp/webp рекурсивно.

## Запуск

```bash
docker compose build

# 1. побудувати базу з data/people
docker compose run --rm kcv learn

# 2. розпізнати все з data/queries (або вкажіть файл/папку, шлях усередині контейнера: /data/...)
docker compose run --rm kcv identify
docker compose run --rm kcv identify /data/queries/photo.jpg

# 3. перевірити точність на data/test
docker compose run --rm kcv test --threshold 0.5
```

## Локальний API

Спочатку побудуйте базу розпізнавання, якщо `data/models/embeddings.pkl` ще немає. Потім запустіть API та вебклієнт:

```bash
docker compose run --rm kcv learn
docker compose up --build
```

Вебінтерфейс Next.js доступний на `http://localhost:3000`. FastAPI доступне напряму лише локально на `http://localhost:5001`; перевірка стану — `GET /health`, інтерактивна документація — `http://localhost:5001/docs`.

Для розпізнавання API приймає `POST /identify` із зображенням у полі multipart-форми `file` (до 10 МБ):

```bash
curl.exe -F "file=@photo.jpg" http://localhost:5001/identify
```

Вебклієнт надсилає `POST /api/identify` на Next.js, який проксіює запит до FastAPI. Тому окреме налаштування CORS для браузера не потрібне. Відповідь містить `prediction`, `similarity`, `face_probability`, найкращих кандидатів і `threshold`; `prediction` може бути `unknown` або `no_face`.

## Поріг

У `data/output/identify_diagnostics.csv` також є `face_probability` (впевненість MTCNN),
два найближчі кандидати з їхніми `similarity` та `margin` — різницею між їхніми оцінками.
Низька впевненість вказує на проблему детекції, а малий `margin` — на неоднозначність між кандидатами.

`THRESHOLD` — мінімальна косинусна схожість (0.5 за замовчуванням). Нижче порогу результат `unknown`.
Підберіть його через `test`, додавши в `test/` також фото людей не з вашої групи
(у вигляді окремої папки, наприклад `test/unknown/`) — тоді для них вірним буде `unknown`.
Для цього в `test` назва папки має збігатися з відповіддю, тому використовуйте ім'я `unknown`.

## Приватність

Обличчя — біометричні дані. Збирайте фото лише зі згоди людей і зберігайте `data/` у безпечному місці.
