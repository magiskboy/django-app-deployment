# Hướng dẫn deploy app django lên môi trường production

Giả sử, mình có project django như sau:
```
── app
│   ├── admin.py
│   ├── apps.py
│   ├── __init__.py
│   ├── migrations
│   ├── models.py
│   ├── static
│   ├── templates
│   ├── tests.py
│   ├── urls.py
│   └── views.py
├── db.sqlite3
├── demo
│   ├── __init__.py
│   ├── settings.py
│   ├── urls.py
│   └── wsgi.py
└── manage.py
```

Trong môi trường development, django có một số tính năng đặc biệt mà trong production không nên sử dụng như debug.
Đê kích hoạt môi trường production trong django, các bạn có thể sửa lại file settings.py như sau:
```python
DEBUG = False if .getenv('DEBUG', '0') == 0 else True
```

Nhưng như vậy ta sẽ gặp một vấn đề việc serve các static file!!!

Mặc định, Django trong chế độ non debug sẽ không chịu trách nhiệm việc serve các static file nên khi tắt chế độ debug, trình duyệt sẽ không tải được các file ảnh, css, js, ...

Bây giờ, khi bạn chạy
```bash
$ ./manage.py runserver
```

trình duyệt vẫn sẽ load được html nhưng các file ảnh, css, js thì không load được do webserver django cung cấp không serve chúng khi DEGUB = False. Vậy ta sẽ phải dùng một webserver khác để serve, ở đây mình chọn nginx.

Đầu tiên, mình sẽ quy định url của static file khi django render template và đường dẫn static file trên host machine. Các config này nên quy định trong demo/settings.py
```python
STATIC_URL = '/static/'
STATIC_ROOT = '/var/demo/static'
```

Tiếp theo, mình sẽ config urlpatterns để mỗi khi template engine của django render html sẽ render đúng url của static file mà mình quy định. Trong demo/urls.py
```python
from django.contrib.staticfiles.urls import static
from django.conf import settings

urlpatterns += static(
    prefix=getattr(settings, 'STATIC_URL'),
    document_root=getattr(settings, 'STATIC_ROOT')
)
```

OK, vậy là mình đã config xong đối với django, giờ sẽ config nginx để serve đúng chỗ của static file, ở đây là **/var/demo/static**
Mình tạo file **/etc/nginx/conf.d/demo.conf**, với nội dung như sau:
```nginx
server {
    listen 80;
    server_name demo;

    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }

    location /static {
        alias /var/demo/static;
    }
}
```

Logic ở đây là, django sẽ render html với các config của mình như url của static file sẽ là **STATIC_URL** và các static file trong môi trường production sẽ được chứa ở **STATIC_ROOT**. Khi browser tải xong html, với url của các static file như vậy, nginx sẽ serve đống static theo **alias**.

Sau khi config xong, mình chạy lệnh sau trong thư mục project của django
```bash
$ gunicorn --bind 127.0.0.1:8000 --workers 2 demo.wsgi:application
```

Các bạn có thể lấy repo này về test thử, https://github.com/thanhngk/django-app-deployment