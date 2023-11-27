1.
Найдите количество вопросов, которые набрали больше 300 очков или как минимум 100 раз были добавлены в «Закладки».
SELECT COUNT(DISTINCT posts.id)
FROM stackoverflow.posts
JOIN stackoverflow.post_types ON post_types.id = posts.post_type_id
WHERE post_types.type = 'Question' AND score >300 OR favorites_count >= 100;

2.
Сколько в среднем в день задавали вопросов с 1 по 18 ноября 2008 включительно? Результат округлите до целого числа.
SELECT COUNT(id),
             creation_date::date
      FROM stackoverflow.posts
      WHERE post_type_id = 1
      GROUP BY creation_date::date
      HAVING creation_date::date BETWEEN '2008-11-01' AND '2008-11-18';  

3.
Сколько пользователей получили значки сразу в день регистрации? Выведите количество уникальных пользователей.
SELECT COUNT(DISTINCT users.id)
FROM stackoverflow.users
JOIN stackoverflow.badges ON badges.user_id = users.id
WHERE badges.creation_date::date = users.creation_date::date;

4.
Сколько уникальных постов пользователя с именем Joel Coehoorn получили хотя бы один голос?
WITH po AS (SELECT posts.id AS post
FROM stackoverflow.posts
JOIN stackoverflow.users ON users.id = posts.user_id
JOIN stackoverflow.votes ON votes.post_id = posts.id
WHERE users.display_name = 'Joel Coehoorn'
GROUP BY posts.id
HAVING COUNT(votes.id) >=1)

SELECT COUNT(post)
FROM po;

5.
Выгрузите все поля таблицы vote_types. Добавьте к таблице поле rank, в которое войдут номера записей в обратном порядке. Таблица должна быть отсортирована по полю id.
SELECT *,
       ROW_NUMBER() OVER (ORDER BY id DESC) AS rank
FROM stackoverflow.vote_types
ORDER BY id;

6.
Отберите 10 пользователей, которые поставили больше всего голосов типа Close. Отобразите таблицу из двух полей: идентификатором пользователя и количеством голосов. Отсортируйте данные сначала по убыванию количества голосов, потом по убыванию значения идентификатора пользователя.
WITH up AS (SELECT DISTINCT votes.user_id AS user_id,
       COUNT (votes.id) OVER (PARTITION BY votes.user_id) AS count_votes
FROM stackoverflow.votes
JOIN stackoverflow.vote_types ON votes.vote_type_id = vote_types.id
WHERE vote_types.name = 'Close')

SELECT user_id,
       count_votes 
FROM up
ORDER BY count_votes DESC, user_id DESC
LIMIT 10;

7.
Отберите 10 пользователей по количеству значков, полученных в период с 15 ноября по 15 декабря 2008 года включительно.
Отобразите несколько полей:
идентификатор пользователя;
число значков;
место в рейтинге — чем больше значков, тем выше рейтинг.
Пользователям, которые набрали одинаковое количество значков, присвойте одно и то же место в рейтинге.
Отсортируйте записи по количеству значков по убыванию, а затем по возрастанию значения идентификатора пользователя.

WITH u_b AS (SELECT badges.user_id AS user_id,
       COUNT (badges.id) AS count_badges    
FROM stackoverflow.badges
WHERE creation_date::date BETWEEN '2008-11-15' AND '2008-12-15'
GROUP BY user_id)

SELECT user_id,
       count_badges,
       DENSE_RANK() OVER (ORDER BY count_badges DESC) AS rn
FROM u_b
ORDER BY count_badges DESC, user_id
LIMIT 10;

8.
Сколько в среднем очков получает пост каждого пользователя? Сформируйте таблицу из следующих полей: заголовок поста; идентификатор пользователя; число очков поста; среднее число очков пользователя за пост, округлённое до целого числа. Не учитывайте посты без заголовка, а также те, что набрали ноль очков.
WITH r AS (
SELECT ROUND(AVG(score)) AS avg_score,
       user_id
FROM stackoverflow.posts
WHERE title IS NOT NULL 
   AND score <> 0
GROUP BY user_id
)

SELECT p.title,
       r.user_id,
       p.score,
       r.avg_score
FROM r 
JOIN stackoverflow.posts AS p ON r.user_id=p.user_id
WHERE p.title IS NOT NULL 
   AND p.score <> 0;  

9.
Отобразите заголовки постов, которые были написаны пользователями, получившими более 1000 значков. Посты без заголовков не должны попасть в список.
WITH b AS (SELECT users.id AS users,
       COUNT(users.id)
FROM stackoverflow.users
JOIN stackoverflow.badges ON badges.user_id = users.id
GROUP BY users.id
HAVING COUNT(users.id)>1000)

SELECT posts.title
FROM stackoverflow.posts
RIGHT JOIN b ON b.users = posts.user_id
WHERE posts.title IS NOT NULL;

10.
Напишите запрос, который выгрузит данные о пользователях из Канады (англ. Canada). Разделите пользователей на три группы в зависимости от количества просмотров их профилей:
пользователям с числом просмотров больше либо равным 350 присвойте группу 1;
пользователям с числом просмотров меньше 350, но больше либо равно 100 — группу 2;
пользователям с числом просмотров меньше 100 — группу 3.
Отобразите в итоговой таблице идентификатор пользователя, количество просмотров профиля и группу. Пользователи с количеством просмотров меньше либо равным нулю не должны войти в итоговую таблицу.

WITH lo AS (SELECT id
FROM stackoverflow.users
WHERE location LIKE '%Canada%' AND views > 0)

SELECT id, 
       views,
    CASE WHEN views >= 350 THEN 1
         WHEN views >= 100 AND views < 350  THEN 2
         WHEN views < 100 THEN 3
   END
FROM stackoverflow.users
WHERE id IN (SELECT id
                  FROM lo);


11.
Дополните предыдущий запрос. Отобразите лидеров каждой группы — пользователей, которые набрали максимальное число просмотров в своей группе. Выведите поля с идентификатором пользователя, группой и количеством просмотров. Отсортируйте таблицу по убыванию просмотров, а затем по возрастанию значения идентификатора.

WITH lo AS (SELECT id
            FROM stackoverflow.users
            WHERE location LIKE '%Canada%' AND views > 0),

vi AS (SELECT id, 
                   views,
                   CASE WHEN views >= 350 THEN 1
                   WHEN views >= 100 AND views < 350  THEN 2
                   WHEN views < 100 THEN 3
                   END
            FROM stackoverflow.users
            WHERE id IN (SELECT id
                         FROM lo)),
                  
m_1 AS (SELECT MAX(views) AS max_1
FROM vi
WHERE vi.case = 1),

m_2 AS (SELECT MAX(views) AS max_2
FROM vi
WHERE vi.case = 2),

m_3 AS (SELECT MAX(views) AS max_3
FROM vi
WHERE vi.case = 3)

SELECT vi.id,
       vi.case,
       vi.views
FROM vi
WHERE vi.views IN (select *
                  from m_1) OR vi.views IN (select *
                  from m_2) OR vi.views IN (select *
                  from m_3)
ORDER BY vi.views DESC, vi.id;

12.
Посчитайте ежедневный прирост новых пользователей в ноябре 2008 года. Сформируйте таблицу с полями:
номер дня;
число пользователей, зарегистрированных в этот день;
сумму пользователей с накоплением.


SELECT DISTINCT EXTRACT(day FROM creation_date) AS creation_date,
       COUNT (id) OVER (PARTITION BY CAST(DATE_TRUNC('day', creation_date) AS date)) AS count_event,
       COUNT (id) OVER (ORDER BY CAST(DATE_TRUNC('day', creation_date) AS date))
FROM stackoverflow.users
WHERE EXTRACT(year FROM creation_date) = 2008 AND EXTRACT(month FROM creation_date) = 11;


13.
Для каждого пользователя, который написал хотя бы один пост, найдите интервал между регистрацией и временем создания первого поста. Отобразите:
идентификатор пользователя;
разницу во времени между регистрацией и первым постом.

WITH date_re AS (SELECT DISTINCT id AS id_u,
       creation_date AS creation_date
FROM stackoverflow.users),

date_po AS (SELECT user_id,
       MIN(creation_date) AS first_date_post
FROM stackoverflow.posts
GROUP BY user_id)

SELECT date_re.id_u,
       first_date_post - creation_date
FROM date_re
JOIN date_po ON date_po.user_id = date_re.id_u;


14.
Выведите общую сумму просмотров у постов, опубликованных в каждый месяц 2008 года. Если данных за какой-либо месяц в базе нет, такой месяц можно пропустить. Результат отсортируйте по убыванию общего количества просмотров.

WITH po AS(SELECT DISTINCT CAST(DATE_TRUNC('month', creation_date) AS date) AS creation_month,
        SUM (views_count) OVER (PARTITION BY CAST(DATE_TRUNC('month', creation_date) AS date)) AS views_posts
FROM stackoverflow.posts
WHERE EXTRACT(year FROM creation_date) =2008)

SELECT views_posts,
       creation_month
FROM po
ORDER BY views_posts DESC;


15.
Выведите имена самых активных пользователей, которые в первый месяц после регистрации (включая день регистрации) дали больше 100 ответов. Вопросы, которые задавали пользователи, не учитывайте. Для каждого имени пользователя выведите количество уникальных значений user_id. Отсортируйте результат по полю с именами в лексикографическом порядке.
SELECT u.display_name,
       COUNT(DISTINCT p.user_id)
FROM stackoverflow.posts AS p
JOIN stackoverflow.users AS u ON p.user_id = u.id
JOIN stackoverflow.post_types AS pt ON pt.id = p.post_type_id
WHERE p.creation_date::date BETWEEN u.creation_date::date AND (u.creation_date::date + INTERVAL '1 month')
   AND pt.type LIKE '%Answer%'
GROUP BY u.display_name
HAVING COUNT(p.id) > 100
ORDER BY u.display_name;


16.
Выведите количество постов за 2008 год по месяцам. Отберите посты от пользователей, которые зарегистрировались в сентябре 2008 года и сделали хотя бы один пост в декабре того же года. Отсортируйте таблицу по значению месяца по убыванию.

WITH po AS (SELECT users.id
FROM stackoverflow.users
JOIN stackoverflow.posts ON posts.user_id = users.id
WHERE EXTRACT(month FROM users.creation_date) = 9 AND EXTRACT(year FROM users.creation_date) =2008),

so AS (SELECT users.id
FROM stackoverflow.users
JOIN stackoverflow.posts ON posts.user_id = users.id
WHERE EXTRACT(month FROM posts.creation_date) = 12 AND EXTRACT(year FROM posts.creation_date) =2008),

ko AS (SELECT DISTINCT po.id
FROM po
INNER JOIN so ON po.id=so.id)

SELECT COUNT(posts.id), 
       CAST(DATE_TRUNC('month', posts.creation_date) AS date)
FROM stackoverflow.posts
JOIN stackoverflow.users ON posts.user_id = users.id
WHERE users.id IN (SELECT DISTINCT po.id
FROM po
INNER JOIN so ON po.id=so.id)
GROUP BY CAST(DATE_TRUNC('month', posts.creation_date) AS date)
ORDER BY CAST(DATE_TRUNC('month', posts.creation_date) AS date) DESC;


17.
Используя данные о постах, выведите несколько полей:
идентификатор пользователя, который написал пост;
дата создания поста;
количество просмотров у текущего поста;
сумма просмотров постов автора с накоплением.
Данные в таблице должны быть отсортированы по возрастанию идентификаторов пользователей, а данные об одном и том же пользователе — по возрастанию даты создания поста.

SELECT posts.user_id,
       posts.creation_date,
       posts.views_count,
       SUM(views_count) OVER (PARTITION BY posts.user_id ORDER BY posts.creation_date)
FROM stackoverflow.posts
ORDER BY posts.user_id, posts.creation_date;


18.
Сколько в среднем дней в период с 1 по 7 декабря 2008 года включительно пользователи взаимодействовали с платформой? Для каждого пользователя отберите дни, в которые он или она опубликовали хотя бы один пост. Нужно получить одно целое число — не забудьте округлить результат.

WITH po AS (SELECT user_id,
       creation_date::date AS creation_date
FROM stackoverflow.posts
WHERE creation_date::date BETWEEN '2008-12-1' AND '2008-12-7'),

so AS (SELECT user_id, 
       COUNT(DISTINCT creation_date) AS count_day
FROM po
GROUP BY user_id)

SELECT ROUND(AVG(count_day))
FROM so;


19.
На сколько процентов менялось количество постов ежемесячно с 1 сентября по 31 декабря 2008 года? Отобразите таблицу со следующими полями:
Номер месяца.
Количество постов за месяц.
Процент, который показывает, насколько изменилось количество постов в текущем месяце по сравнению с предыдущим.
Если постов стало меньше, значение процента должно быть отрицательным, если больше — положительным. Округлите значение процента до двух знаков после запятой.
Напомним, что при делении одного целого числа на другое в PostgreSQL в результате получится целое число, округлённое до ближайшего целого вниз. Чтобы этого избежать, переведите делимое в тип numeric.

WITH co_po AS (SELECT EXTRACT(month FROM creation_date) AS month_creation,
       COUNT(id) AS count_posts
FROM stackoverflow.posts
WHERE creation_date::date BETWEEN '2008-09-1' AND '2008-12-31'
GROUP BY EXTRACT(month FROM creation_date)),

po_po AS (SELECT month_creation,
       count_posts,
       LAG(count_posts) OVER (ORDER BY month_creation) AS previous_month
FROM co_po)

SELECT month_creation,
       count_posts,
       ROUND(((count_posts::numeric/previous_month::numeric)*100)-100::numeric,2) AS ch
FROM po_po;


20.
Найдите пользователя, который опубликовал больше всего постов за всё время с момента регистрации. Выведите данные его активности за октябрь 2008 года в таком виде:
номер недели;
дата и время последнего поста, опубликованного на этой неделе.


SELECT EXTRACT(week FROM creation_date),
       MAX(creation_date)
FROM stackoverflow.posts
WHERE DATE_TRUNC('month', creation_date)::date = '2008-10-01' AND posts.user_id IN (SELECT posts.user_id AS user_id
FROM stackoverflow.posts
GROUP BY posts.user_id
ORDER BY COUNT(id) DESC
LIMIT 1)

GROUP BY EXTRACT(week FROM creation_date)
