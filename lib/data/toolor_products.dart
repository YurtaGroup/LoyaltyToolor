// Product data fetched and parsed from toolorkg.com
// Toolor - International brand of functional outerwear and accessories
// inspired by digital nomad aesthetics and lifestyle.
// Based in Bishkek, Kyrgyzstan.
//
// Currency: Kyrgyzstani Som (KGS)
// Last fetched: 2026-03-23
// Total products: 113

class Toolor {
  static const String brandName = 'Toolor';
  static const String brandDescription =
      'Международный бренд функциональной верхней одежды и аксессуаров, '
      'вдохновленный эстетикой и стилем жизни digital-номадов';
  static const String phone = '+996 998 844 444';
  static const String email = 'salestoolor@coolgroup.kg';
  static const String address = 'Бишкек, AsiaMall, 2 этаж, бутик 19(1)';
  static const String workingHours = 'Ежедневно 10:00–22:00';
  static const String currency = 'сом';
  static const String baseUrl = 'https://toolorkg.com';
}

// ---------------------------------------------------------------------------
// Category & subcategory constants
// ---------------------------------------------------------------------------

class ProductCategory {
  static const String men = 'Мужчинам';
  static const String women = 'Женщинам';
  static const String accessories = 'Аксессуары';
  static const String sale = 'Скидки';
}

class ProductSubcategory {
  // Shared clothing
  static const String tshirts = 'Футболки';
  static const String longsleeves = 'Лонгсливы';
  static const String sweatshirts = 'Свитшоты';
  static const String hoodies = 'Худи';
  static const String shirts = 'Рубашки';
  static const String knitwear = 'Вязаный трикотаж';
  static const String pants = 'Брюки';
  static const String shorts = 'Шорты';
  static const String jackets = 'Куртки';
  static const String downJackets = 'Пуховики';
  static const String windbreakers = 'Ветровки';
  static const String fleece = 'Флис';
  static const String vests = 'Жилеты';
  static const String sets = 'Костюмы';
  static const String cardigans = 'Кардиган';
  static const String sweaters = 'Свитер';
  static const String turtlenecks = 'Водолазки';
  static const String lightdown = 'Лайтдаун';
  static const String zippers = 'Зипки';
  static const String trench = 'Тренчи';
  static const String bodies = 'Боди';

  // Accessories
  static const String scarves = 'Шарфы';
  static const String bags = 'Сумки';
  static const String caps = 'Кепки';
  static const String hats = 'Шапки';
  static const String cases = 'Чехлы';
  static const String other = 'Другое';
}

// ---------------------------------------------------------------------------
// All 113 products from toolorkg.com/shop (scraped from product sitemap)
// ---------------------------------------------------------------------------

final List<Map<String, dynamic>> toolorProducts = [
  // =========================================================================
  // АКСЕССУАРЫ
  // =========================================================================
  {
    'id': 'acc-001',
    'name': 'Джинсовые кепки',
    'price': 1290,
    'originalPrice': null,
    'imageUrl':
        'https://toolorkg.com/wp-content/uploads/2025/03/WhatsApp-Image-2025-03-07-at-08.51.24-4.jpeg',
    'category': ProductCategory.accessories,
    'subcategory': ProductSubcategory.caps,
    'description': 'Джинсовая кепка – удобная, прочная и представлена в стилизации с животным дизайном . Изготовленная из высококачественного денима, она добавит в ваш образ внимание и обеспечит надежную защиту от солнца. Нетипичный дизайн с приглушонным цветом делают её подходящей как для повседневных прогулок, так...',
    'sizes': [],
    'colors': ['Графит', 'Коричневый', 'Хаки'],
  },
  {
    'id': 'acc-002',
    'name': 'Стеганная сумка шоппер',
    'price': 1890,
    'originalPrice': 2990,
    'imageUrl':
        'https://toolorkg.com/wp-content/uploads/2025/01/cccc73573160.webp',
    'category': ProductCategory.accessories,
    'subcategory': ProductSubcategory.bags,
    'description': 'Стеганная сумка шоппер объемная и вместительная , с мягким ремешком застегивается на молнию, внутри имеются карманы , большой карман предназначен для ноутбуков и есть еще два для личных вещей.  Пол: Женский Пол: Мужской',
    'sizes': [],
    'colors': ['Лайм', 'Петроль', 'Электро-синий'],
  },
  {
    'id': 'acc-003',
    'name': 'Шоппер-трансформер',
    'price': 1890,
    'originalPrice': null,
    'imageUrl':
        'https://toolorkg.com/wp-content/uploads/2024/11/15030672.jpg.webp',
    'category': ProductCategory.accessories,
    'subcategory': ProductSubcategory.bags,
    'description': 'Черный трансформирующийся шоппер. По бокам расположены резинки со стоперами для возможности драпировать и варьировать размер шоппера. Также внутри есть удобный кармашек на молнии  Пол: Женский Пол: Мужской',
    'sizes': [],
    'colors': ['Черный'],
  },
  {
    'id': 'acc-004',
    'name': 'Стеганный чехол для ноутбука',
    'price': 1290,
    'originalPrice': 1990,
    'imageUrl':
        'https://toolorkg.com/wp-content/uploads/2025/01/cheh35512555.webp',
    'category': ProductCategory.accessories,
    'subcategory': ProductSubcategory.cases,
    'description': 'Стеганный чехол для ноутбука , с клапаном на липучке, защитит ноутбук от повреждений ударов  Пол: Женский Пол: Мужской',
    'sizes': [],
    'colors': ['Графит', 'Лайм', 'Светло-розовый'],
  },
  {
    'id': 'acc-005',
    'name': 'Стеганный шарф',
    'price': 1890,
    'originalPrice': 2990,
    'imageUrl':
        'https://toolorkg.com/wp-content/uploads/2025/01/shsh12144931.webp',
    'category': ProductCategory.accessories,
    'subcategory': ProductSubcategory.scarves,
    'description': 'Шарф стеганный с наполнителем с двумя отверстиями, для того чтобы легко закрепить и задрапировать его',
    'sizes': [],
    'colors': ['Лайм', 'Светло-розовый', 'Синий', 'Черный'],
  },
  // =========================================================================
  // ЖЕНЩИНАМ
  // =========================================================================
  {
    'id': 'women-001',
    'name': 'Женская рубашка в полоску',
    'price': 6990,
    'originalPrice': null,
    'imageUrl':
        'https://toolorkg.com/wp-content/uploads/2025/05/0F2A5199.jpg',
    'category': ProductCategory.women,
    'subcategory': ProductSubcategory.bodies,
    'description': 'Особенности:  * Длинные рукава * Отложной воротник * Центральная застежка на пуговицах * Минималистичный карман на левой груди * Мягкий текстурный хлопок * Фирменный кожанная нашивка',
    'sizes': ['S', 'M', 'L', 'XL'],
    'colors': ['Бежевый', 'Голубой', 'Светло-голубой'],
  },
  {
    'id': 'women-002',
    'name': 'Женский Боди',
    'price': 1399,
    'originalPrice': null,
    'imageUrl':
        'https://toolorkg.com/wp-content/uploads/2024/12/6P3A0890.jpg',
    'category': ProductCategory.women,
    'subcategory': ProductSubcategory.bodies,
    'description': 'Комфортное базовое боди - универсальная основа любого образа.  Особенности: *Круглый вырез воротника *Длинные рукава *Эластичная и комфортная',
    'sizes': ['XS/S', 'S/M', 'M/L'],
    'colors': ['Айвори', 'Бежевый', 'Винный'],
  },
  {
    'id': 'women-003',
    'name': 'Женский Боди супрем',
    'price': 1399,
    'originalPrice': null,
    'imageUrl':
        'https://toolorkg.com/wp-content/uploads/2024/12/6P3A0864.jpg',
    'category': ProductCategory.women,
    'subcategory': ProductSubcategory.bodies,
    'description': 'Комфортное базовое боди - универсальная основа любого образа.  Особенности: *Круглый вырез воротника *Длинные рукава *Дышащая и эластичная',
    'sizes': ['XS/S', 'S/M', 'M/L'],
    'colors': ['Айвори', 'Серый меланж', 'Серый', 'Темно-синий'],
  },
  {
    'id': 'women-004',
    'name': 'Женская двойка с лампасами',
    'price': 4949,
    'originalPrice': null,
    'imageUrl':
        'https://toolorkg.com/wp-content/uploads/2025/03/WhatsApp-Image-2025-03-07-at-11.36.44-7.jpeg',
    'category': ProductCategory.women,
    'subcategory': ProductSubcategory.pants,
    'description': 'Укороченный свитшот из трехнитки с накладным карманом в стиле милитари из плащевки в сочетании с палаццо брюками из плащевки — стильный и комфортный комплект для активных и любящих свободу в движении. Современный дизайн с вышивкой и функциональные элементы создают идеальный образ не только для го...',
    'sizes': ['XS/S', 'M/L'],
    'colors': ['Сине-зеленый', 'Хаки', 'Черный'],
  },
  {
    'id': 'women-005',
    'name': 'Женские брюки',
    'price': 3400,
    'originalPrice': null,
    'imageUrl':
        'https://toolorkg.com/wp-content/uploads/2024/12/0F2A0190-1.jpg',
    'category': ProductCategory.women,
    'subcategory': ProductSubcategory.pants,
    'description': 'Женская спортивная в тоже время утонченная двойка свитшот-брюки для вашего акцентного образа.  Особенности: * Свободный силуэт свитшота и брюк * Лакончный принт лого и рунической надписи «Кочевники будущего»',
    'sizes': ['XS', 'S', 'M', 'L', 'XL'],
    'colors': ['Айвори', 'Бежевый', 'Графит'],
  },
  {
    'id': 'women-006',
    'name': 'Женские брюки',
    'price': 2799,
    'originalPrice': null,
    'imageUrl':
        'https://toolorkg.com/wp-content/uploads/2025/10/DSC05128_resized.jpeg',
    'category': ProductCategory.women,
    'subcategory': ProductSubcategory.pants,
    'description': 'Осень в мягком касании. Комплект из тенселя обнимает лёгкостью, дарит свободу движения и спокойную уверенность. Он создан для тёплых прогулок и гармонии внутри тебя.  Натуральная ткань тенсель дарит ощущение мягкости и лёгкости, приятна к телу и позволяет коже дышать. Минималистичный силуэт и спо...',
    'sizes': ['S', 'M', 'L', 'XL'],
    'colors': ['Бежевый', 'Серый'],
  },
  {
    'id': 'women-007',
    'name': 'Женские брюки',
    'price': 3250,
    'originalPrice': null,
    'imageUrl':
        'https://toolorkg.com/wp-content/uploads/2024/12/0F2A1066.jpg',
    'category': ProductCategory.women,
    'subcategory': ProductSubcategory.pants,
    'description': 'Женская двойка свитшот-брюки из ткани "Трехнитки" с ярким дизайном вышивки, вдохновленным силуэтом "Тундука" юрты, станет ярким дополнением вашего гардероба.  Особенности: *Круглый вырез воротника * Конструктивные рельефы, подчеркивающие силуэт юрты * Лаконичная вышивка с силуэтом "Тундука" юрты ...',
    'sizes': ['XS', 'S', 'M', 'L', 'XL'],
    'colors': ['Бордовый', 'Графит', 'Коричневый', 'Оливковый'],
  },
  {
    'id': 'women-008',
    'name': 'Женские брюки "Микровельвет"',
    'price': 3090,
    'originalPrice': null,
    'imageUrl':
        'https://toolorkg.com/wp-content/uploads/2025/05/0F2A8068-1.jpg',
    'category': ProductCategory.women,
    'subcategory': ProductSubcategory.pants,
    'description': 'Брюки, которые работают на тебя ! Прямые спортивные брюки от Toolor - это не про спорт. Это про тебя - активную, мобильную, настоящую. Прямой крой подчеркивает фигуру, не стесняя движений, а легкая и дышащая ткань держит форму и заботится о твоем комфорте в течении дня. Надень их на тренировку, в...',
    'sizes': ['XS', 'S', 'M', 'L', 'XL'],
    'colors': ['Айвори', 'Бордовый', 'Графит', 'Черный'],
  },
  {
    'id': 'women-009',
    'name': 'Женские брюки бананки',
    'price': 0,
    'originalPrice': null,
    'imageUrl':
        '',
    'category': ProductCategory.women,
    'subcategory': ProductSubcategory.pants,
    'description': '',
    'sizes': [],
    'colors': [],
  },
  {
    'id': 'women-010',
    'name': 'Женские брюки с манжетой',
    'price': 2799,
    'originalPrice': null,
    'imageUrl':
        'https://toolorkg.com/wp-content/uploads/2025/03/WhatsApp-Image-2025-03-07-at-08.40.02.jpeg',
    'category': ProductCategory.women,
    'subcategory': ProductSubcategory.pants,
    'description': 'Брюки в стиле джоггеров – удобство и свобода движений !  * Расслабленный силуэт с манжетами – комфорт и фиксация ноги. * Накладные «портфельные» карманы – вместительные, удобные, добавляют характер. * Эластичный пояс – резинка сзади и по бокам для комфортной посадки.  Этот вариант для тех, кто вы...',
    'sizes': ['S', 'M', 'L', 'XL', 'XXL'],
    'colors': ['Оливковый', 'Хаки'],
  },
  {
    'id': 'women-011',
    'name': 'Женские брюки трубы',
    'price': 3600,
    'originalPrice': null,
    'imageUrl':
        'https://toolorkg.com/wp-content/uploads/2025/10/DSC05207_resized.jpeg',
    'category': ProductCategory.women,
    'subcategory': ProductSubcategory.pants,
    'description': 'Женская зипка в комплекте с брюками из коллекции “Sandyk”. На спине — половина традиционного кыргызского орнамента с четырьмя симметричными сторонами. Он несёт в себе символику единения и гармонии мира.  Асимметрия здесь не случайна: она отражает движение и поиск. Центр орнамента — это девушка, к...',
    'sizes': ['XL/2XL', 'S', 'M', 'L', 'XL'],
    'colors': ['Бордовый', 'Кофе', 'Оливковый'],
  },
  {
    'id': 'women-012',
    'name': 'Женские вафельные брюки',
    'price': 2799,
    'originalPrice': null,
    'imageUrl':
        'https://toolorkg.com/wp-content/uploads/2025/03/WhatsApp-Image-2025-03-07-at-08.39.38.jpeg',
    'category': ProductCategory.women,
    'subcategory': ProductSubcategory.pants,
    'description': 'Брюки в стиле милитари – классика с акцентом на функциональность !  * Классический крой с тактическими элементами – строгий силуэт с удобными деталями. * Функциональные карманы – молнии и накладные карманы для необходимых мелочей. * Комфортная посадка – пояс на резинке, а спереди –на кнопке.  Иде...',
    'sizes': ['S', 'M', 'L', 'XL', 'XXL'],
    'colors': ['Графит', 'Оливковый'],
  },
  {
    'id': 'women-013',
    'name': 'Женские стильные брюки',
    'price': 3600,
    'originalPrice': null,
    'imageUrl':
        'https://toolorkg.com/wp-content/uploads/2024/12/0F2A0415-scaled.jpg',
    'category': ProductCategory.women,
    'subcategory': ProductSubcategory.pants,
    'description': 'Базовая двойка худи c капюшоном и брюками, выполненная в минималистичном стиле, станет удобным и стильным элементом вашего гардероба. Комплект декарирован вышивкой логотипа и слогана «Кочевники будущего», в тон основного материала, что придает комплекту-современный и глубокий смысл.  Особенность ...',
    'sizes': ['XS/S', 'S/M', 'M/L'],
    'colors': ['Айвори', 'Бежевый', 'Графит', 'Розовый'],
  },
  {
    'id': 'women-014',
    'name': 'Женская ветровка',
    'price': 3499,
    'originalPrice': null,
    'imageUrl':
        'https://toolorkg.com/wp-content/uploads/2025/10/bezhevaya-dvojka-scaled.jpg',
    'category': ProductCategory.women,
    'subcategory': ProductSubcategory.windbreakers,
    'description': 'Осень в мягком касании. Комплект из тенселя обнимает лёгкостью, дарит свободу движения и спокойную уверенность. Он создан для тёплых прогулок и гармонии внутри тебя.  Натуральная ткань тенсель дарит ощущение мягкости и лёгкости, приятна к телу и позволяет коже дышать. Минималистичный силуэт и спо...',
    'sizes': ['S', 'M', 'L', 'XL'],
    'colors': ['Бежевый', 'Серый'],
  },
  {
    'id': 'women-015',
    'name': 'Женская ветровка Тенсел',
    'price': 4700,
    'originalPrice': null,
    'imageUrl':
        'https://toolorkg.com/wp-content/uploads/2025/06/2025-05-20-03-13-34-737068_resized.jpeg',
    'category': ProductCategory.women,
    'subcategory': ProductSubcategory.windbreakers,
    'description': 'Натуральный материал. Современный ритм. Изготовленная из тенселя - экологичной и устойчивой ткани, эта ветровка обьединяет заботу о природе в твоем теле. Легкая, дышащая, с расслабленным силуэтом и отложным воротником - она станет твоей любимой вещью на каждый день. Стиль вне сезона. Гармония вне...',
    'sizes': ['S', 'M', 'L', 'XL'],
    'colors': ['Кофе', 'Светло-золотистый', 'Светло-серый', 'Фисташковый'],
  },
  {
    'id': 'women-016',
    'name': 'Женская ветровка вафелька',
    'price': 4000,
    'originalPrice': null,
    'imageUrl':
        'https://toolorkg.com/wp-content/uploads/2025/06/DSC02972_resized.jpeg',
    'category': ProductCategory.women,
    'subcategory': ProductSubcategory.windbreakers,
    'description': 'Стильная и легкая ветровка для динамичных дней. Легкий прямой крой, ветрозащитный, водоотталкивающий материал, удобные карманы и капюшон обеспечивают комфорт в любую погоду. Низ с утяжной резинкой с фиксатором позволяет регулировать посадку, а застежка на молнии надежно прослужит вам ни один сезо...',
    'sizes': ['S', 'M', 'L', 'XL', 'XXL'],
    'colors': ['Белый', 'Фисташковый', 'Черный'],
  },
  {
    'id': 'women-017',
    'name': 'Женская ветровка оверсайз',
    'price': 4000,
    'originalPrice': null,
    'imageUrl':
        'https://toolorkg.com/wp-content/uploads/2025/06/2025-05-20-02-49-05-817002_resized.jpeg',
    'category': ProductCategory.women,
    'subcategory': ProductSubcategory.windbreakers,
    'description': 'Особенности: * Оверсайз фасон * Контрастная окантовка * Воротник стойка * Низ рукава на манжете * Низ утягивается на стопперах * Удобные карманы в рельефах * Центральная застежка на молнии * Легкий ветрозащитный и водоотталкивающий материал * Фирменный металлический шеврон',
    'sizes': ['S', 'M', 'L', 'XL'],
    'colors': ['Айвори', 'Белый', 'Серый', 'Фисташковый'],
  },
  {
    'id': 'women-018',
    'name': 'Женская водолазка',
    'price': 4499,
    'originalPrice': null,
    'imageUrl':
        'https://toolorkg.com/wp-content/uploads/2024/12/0F2A1303.jpg',
    'category': ProductCategory.women,
    'subcategory': ProductSubcategory.turtlenecks,
    'description': 'Водолазка с высоким воротником от Toolor выполнен из гипоаллергенной пряжи высокого качества. Продуманный крой с плавной линией плеча и аккуратной брендированной вышивкой делает его идеальным дополнением для уютных повседневных образов.  Особенности: * Высокий воротник * Рукава и низ на манжете *...',
    'sizes': ['XS/S', 'M/L', 'XL/2XL'],
    'colors': ['Бежевый', 'Винный', 'Графит'],
  },
  {
    'id': 'women-019',
    'name': 'Короткая двусторонняя куртка-трансформер',
    'price': 11990,
    'originalPrice': 18990,
    'imageUrl':
        'https://toolorkg.com/wp-content/uploads/2025/01/88888888863645178.webp',
    'category': ProductCategory.women,
    'subcategory': ProductSubcategory.vests,
    'description': 'Короткая двухсторонняя куртка, оверсайз с отстегивающимися рукавами. Рукава расстегиваются , для возможности носить куртку как жилет. Жилет так же как и куртка двухсторонний за счет специальной перекидной молнии. По низу изделия манжеты на резинки , для фиксирования и защиты от холодного воздуха ...',
    'sizes': ['S', 'M', 'L', 'XL'],
    'colors': ['Лайм'],
  },
  {
    'id': 'women-020',
    'name': 'Короткая двусторонняя куртка-трансформер',
    'price': 11990,
    'originalPrice': 18990,
    'imageUrl':
        'https://toolorkg.com/wp-content/uploads/2025/01/ppv44545954.jpg',
    'category': ProductCategory.women,
    'subcategory': ProductSubcategory.vests,
    'description': '"Короткая двухсторонняя куртка, оверсайз с отстегивающимися рукавами. Рукава расстегиваются , для возможности носить куртку как жилет. Жилет так же как и куртка двухсторонний за счет специальной перекидной молнии. По низу изделия манжеты на резинки , для фиксирования и защиты от холодного воздуха...',
    'sizes': ['S', 'M', 'L', 'XL'],
    'colors': ['Светло-фиолетовый'],
  },
  {
    'id': 'women-021',
    'name': 'Женская зипка с завязкой',
    'price': 3800,
    'originalPrice': null,
    'imageUrl':
        'https://toolorkg.com/wp-content/uploads/2025/10/krasnyj-kostyum-scaled.jpg',
    'category': ProductCategory.women,
    'subcategory': ProductSubcategory.zippers,
    'description': 'Женская зипка в комплекте с брюками из коллекции “Sandyk”. На спине — половина традиционного кыргызского орнамента с четырьмя симметричными сторонами. Он несёт в себе символику единения и гармонии мира.  Асимметрия здесь не случайна: она отражает движение и поиск. Центр орнамента — это девушка, к...',
    'sizes': ['XL/2XL', 'S', 'M', 'L'],
    'colors': ['Бордовый', 'Кофе', 'Оливковый'],
  },
  {
    'id': 'women-022',
    'name': 'Женская корсетная зипка с капюшоном',
    'price': 0,
    'originalPrice': null,
    'imageUrl':
        '',
    'category': ProductCategory.women,
    'subcategory': ProductSubcategory.zippers,
    'description': '',
    'sizes': [],
    'colors': [],
  },
  {
    'id': 'women-023',
    'name': 'Женская олимпийка "Микровельвет"',
    'price': 3290,
    'originalPrice': null,
    'imageUrl':
        'https://toolorkg.com/wp-content/uploads/2025/05/0F2A8003-1.jpg',
    'category': ProductCategory.women,
    'subcategory': ProductSubcategory.zippers,
    'description': 'Никаких рамок - только ты и твой ритм. Олимпийка, которая подчеркивает фигуру, не сковывает и смотрится круто в любом сочетании. Приталенная посадка, реглан и удобная молния - всё, чтобы двигаться быстро уверенно и с кайфом. Надевай под спортивные брюки, джинсы или юбку - без правил, только энергия.',
    'sizes': ['XS', 'S', 'M', 'L', 'XL'],
    'colors': ['Айвори', 'Бордовый', 'Графит', 'Черный'],
  },
  {
    'id': 'women-024',
    'name': 'Женская спортивная зипка без капюшона',
    'price': 3290,
    'originalPrice': null,
    'imageUrl':
        'https://toolorkg.com/wp-content/uploads/2025/10/seryj-kostyum-scaled.jpg',
    'category': ProductCategory.women,
    'subcategory': ProductSubcategory.zippers,
    'description': 'Женская зипка из варёного трикотажа (lining)  Она будто соткана из утреннего тумана — мягкая, с приглушённым переливом оттенков, рожденных техникой «варенка». Каждый её штрих уникален, как акварельный след на ткани, ни одна вещь не повторяет другую.  Свободный крой и удобная молния делают её идеа...',
    'sizes': ['XL/2XL', 'S', 'M', 'L', 'XL'],
    'colors': ['Белый', 'Серый', 'Темно-синий', 'Хаки'],
  },
  {
    'id': 'women-025',
    'name': 'Женский кардиган',
    'price': 3999,
    'originalPrice': null,
    'imageUrl':
        'https://toolorkg.com/wp-content/uploads/2024/12/6P3A0647.jpg',
    'category': ProductCategory.women,
    'subcategory': ProductSubcategory.cardigans,
    'description': 'Женский кардиган  Турецкая пряжа в исполнении специально для "Тоолор" Пряжа, которая в изделии прошла тестовую носку, прежде чем была запущена в производство.  Изделие не деформируется, не вытягивается, на теряет форму и плотность вязки, не пилингуется и претендует стать самым элементом вашего га...',
    'sizes': ['XS/S', 'M/L', 'XL/2XL'],
    'colors': ['Айвори', 'Камель', 'Бордо'],
  },
  {
    'id': 'women-026',
    'name': 'Женский костюм (свитшот-брюки)',
    'price': 3250,
    'originalPrice': null,
    'imageUrl':
        'https://toolorkg.com/wp-content/uploads/2024/12/0F2A0675.jpg',
    'category': ProductCategory.women,
    'subcategory': ProductSubcategory.sets,
    'description': 'Таблица размеров',
    'sizes': ['XS', 'S', 'M', 'L', 'XL'],
    'colors': ['Бордовый', 'Графит', 'Коричневый', 'Оливковый'],
  },
  {
    'id': 'women-027',
    'name': 'Женский спортивный костюм',
    'price': 6799,
    'originalPrice': null,
    'imageUrl':
        'https://toolorkg.com/wp-content/uploads/2025/03/WhatsApp-Image-2025-03-07-at-08.38.00-12.jpeg',
    'category': ProductCategory.women,
    'subcategory': ProductSubcategory.sets,
    'description': 'Женский спортивный костюм с капюшоном из ткани "Трехнитка петелька"  Особенности: * Потайные карманы на свитшоте и на брюках * Фирменная конструкция силуэт Юрты * Низ рукавов на манжете * Пояс на резинке со шнуровкой * Свободный силуэт *Капюшон на шнуровке * Декоративная вышивка лого и рунической...',
    'sizes': ['S', 'M', 'L'],
    'colors': ['Бордовый', 'Графит', 'Оливковый'],
  },
  {
    'id': 'women-028',
    'name': 'Женский спортивный костюм полузамок',
    'price': 6598,
    'originalPrice': null,
    'imageUrl':
        'https://toolorkg.com/wp-content/uploads/2025/03/WhatsApp-Image-2025-03-07-at-11.37.33-6.jpeg',
    'category': ProductCategory.women,
    'subcategory': ProductSubcategory.sets,
    'description': 'Наша женская спортивная двойка с полузамком — идеальный выбор для легкости и комфорта в повседневной жизни. Верх выполнен в виде свитшота с полузамком и воротником, а низ — в широких брюках, которые легко впишутся в стильные образы на каждый день. Дополняют ансамбль функциональные потайные карман...',
    'sizes': ['XS', 'S', 'M', 'L', 'XL'],
    'colors': ['Бежевый', 'Кармеланж', 'Кремовый', 'Темно-синий'],
  },
  {
    'id': 'women-029',
    'name': 'Женская куртка',
    'price': 9000,
    'originalPrice': null,
    'imageUrl':
        'https://toolorkg.com/wp-content/uploads/2025/07/Studio-Session-2636-scaled.jpg',
    'category': ProductCategory.women,
    'subcategory': ProductSubcategory.jackets,
    'description': 'Эта стильная и практичная куртка создана для того, чтобы обеспечить максимальное тепло в холодное время года. Выполнена из высококачественного материала, состоящего на 91% из нейлона и 9% спандекса, что обеспечивает деликатное изготовление, прочность и легкость.',
    'sizes': ['S'],
    'colors': ['Айвори', 'Темно-синий', 'Черный'],
  },
  {
    'id': 'women-030',
    'name': 'Женская куртка чапан',
    'price': 7000,
    'originalPrice': null,
    'imageUrl':
        'https://toolorkg.com/wp-content/uploads/2025/10/chapan-1-scaled.jpg',
    'category': ProductCategory.women,
    'subcategory': ProductSubcategory.jackets,
    'description': 'Куртка-чапан «Umay» из коллекции "Сандык"  Эта женская куртка из искусственной замши — не просто одежда, а символ соединения прошлого и настоящего.  В её линии заложена отсылка к традиционному кыргызскому чапану: воротник-стойка, силуэт с акцентом на талию и лаконичные нагрудные карманы. На спинк...',
    'sizes': ['S', 'M', 'L', 'XL'],
    'colors': ['Коричневый'],
  },
  {
    'id': 'women-031',
    'name': 'Женская шерстяная куртка',
    'price': 7500,
    'originalPrice': null,
    'imageUrl':
        'https://toolorkg.com/wp-content/uploads/2025/10/ajgul-kurtka-scaled.jpg',
    'category': ProductCategory.women,
    'subcategory': ProductSubcategory.jackets,
    'description': 'Айгул гулу — редкий цветок, растущий в кыргызских горах.  Он символизирует любовь, силу и вечность.  Мы перенесли его образ в женскую куртку из коллекции "Сандык". Сочетание мягкого трикотажа и стилизованной вышивки с этническим орнаментом превращает изделие в символ, который можно носить каждый ...',
    'sizes': ['S', 'M', 'L', 'XL'],
    'colors': ['Темно-серый'],
  },
  {
    'id': 'women-032',
    'name': 'Стеганный лайтдаун',
    'price': 6990,
    'originalPrice': null,
    'imageUrl':
        'https://toolorkg.com/wp-content/uploads/2025/01/71884227.jpg',
    'category': ProductCategory.women,
    'subcategory': ProductSubcategory.lightdown,
    'description': 'Легкий стеганный лайтдаун—это легкая курточка которую можно поддеть под плащи куртки, жилеты и зимние пуховики, для дополнительного утепления. Застегивается на кнопках, по переду есть два кармана, так же внутри куртки есть карман со стопором и ремешками , в который можно завернуть куртку и носить...',
    'sizes': ['S', 'M', 'L', 'XL'],
    'colors': ['Белый', 'Светло-зеленый', 'Светло-фиолетовый', 'Черный'],
  },
  {
    'id': 'women-033',
    'name': 'Женский Лонгслив',
    'price': 2550,
    'originalPrice': null,
    'imageUrl':
        'https://toolorkg.com/wp-content/uploads/2024/12/6P3A0856.JPG.jpg',
    'category': ProductCategory.women,
    'subcategory': ProductSubcategory.longsleeves,
    'description': 'Женский оверсайз лонгслив с контрастными рукавами и монохромным этно-принтом.  Особенности: *Круглый вырез воротника *Контрасные рукава реглан *Оверсайз* * Экологически безврредный принт *Нестандартная конструкция *Уникальный этно-принт с авторской иллюстрацией Асии Талип, изображающий быт кочево...',
    'sizes': ['XS', 'S', 'M', 'L', 'XL'],
    'colors': ['Айвори', 'Темно-зеленый', 'Темно-синий'],
  },
  {
    'id': 'women-034',
    'name': 'Женский Лонгслив с вышивкой',
    'price': 2550,
    'originalPrice': null,
    'imageUrl':
        'https://toolorkg.com/wp-content/uploads/2024/12/6P3A1349.jpg',
    'category': ProductCategory.women,
    'subcategory': ProductSubcategory.longsleeves,
    'description': 'Женский оoversize лонгслив для стильного дополнения вашего гардероба.  Особенности: *Круглый вырез воротника *Втачные спущенные рукава *Oversize * Экологически безвредный принт *Представлена в двух вариантах: 1) Вышивка лого спереди и руническая надпись « Кочевники будущего» на спинке 2) Эксклюзи...',
    'sizes': ['XS', 'S', 'M', 'L', 'XL'],
    'colors': ['Кремовый', 'Мята', 'Фиолетовый'],
  },
  {
    'id': 'women-035',
    'name': 'Женский лонгслив',
    'price': 2550,
    'originalPrice': null,
    'imageUrl':
        'https://toolorkg.com/wp-content/uploads/2024/12/6P3A1430.jpg',
    'category': ProductCategory.women,
    'subcategory': ProductSubcategory.longsleeves,
    'description': 'Женский оверсайз лонгслив с контрастными сочетаниями цветов и вставочными рукавами.  Особенности: *Круглый вырез воротника *Декоративные вставки спереди и на рукавах *Спущенные втачные рукава *Оversize *Вышивка лого спереди и рунической надписи « Кочевники будущего» на спинке.',
    'sizes': ['XS', 'S', 'M', 'L', 'XL'],
    'colors': ['Айвори', 'Светло-фиолетовый', 'Серый'],
  },
  {
    'id': 'women-036',
    'name': 'Женский лонгслив лодочка',
    'price': 2250,
    'originalPrice': null,
    'imageUrl':
        'https://toolorkg.com/wp-content/uploads/2025/09/DSC04869_resized.jpeg',
    'category': ProductCategory.women,
    'subcategory': ProductSubcategory.longsleeves,
    'description': 'Базовый лонгслив из мягкой ткани — как дыхание ветра и прикосновение утреннего света. Мягкие оттенки подчёркивают естественность, а прозрачность намекает на хрупкость и силу одновременно.  Это одежда-настроение: невесомая, женственная, созданная для тех, кто говорит с миром языком тонких деталей....',
    'sizes': ['S', 'M', 'L'],
    'colors': ['Черный'],
  },
  {
    'id': 'women-037',
    'name': 'Женский лонгслив с вышивкой',
    'price': 2550,
    'originalPrice': null,
    'imageUrl':
        'https://toolorkg.com/wp-content/uploads/2024/12/6P3A1465.jpg',
    'category': ProductCategory.women,
    'subcategory': ProductSubcategory.longsleeves,
    'description': 'Женский лонгслив c дополнительными вставочными рукавами выполнен в покрое реглан с декоративной тамбурной вышивкой. Вдохновлено свободным Кыргызским народом.  Особенности: *Круглый вырез воротника *Дополнительные вставки на рукавах *Рукава реглан *Оversize *Представлена в двух вариантах: 1) Вышив...',
    'sizes': ['XS', 'S', 'M', 'L'],
    'colors': ['Бежевый', 'Бордовый', 'Серый', 'Темно-синий'],
  },
  {
    'id': 'women-038',
    'name': 'Длинный пуховик оверсайз с поясом',
    'price': 15990,
    'originalPrice': 24990,
    'imageUrl':
        'https://toolorkg.com/wp-content/uploads/2024/11/53267593.jpg.webp',
    'category': ProductCategory.women,
    'subcategory': ProductSubcategory.downJackets,
    'description': 'Длинный пуховик, оверсайз со съемным поясом. По переду имеются карманы на магнитах. В правом кармане есть карабин на резинке, предназначенный для ключей, чтобы они не выпали. Внутренняя часть карманов из флиса, так же во внутренней части рукава имеются трикотажные манжеты, для более комфортной но...',
    'sizes': ['S', 'M', 'L', 'XL'],
    'colors': ['Темно-синий'],
  },
  {
    'id': 'women-039',
    'name': 'Длинный пуховик со съемными шарфами',
    'price': 18990,
    'originalPrice': 29990,
    'imageUrl':
        'https://toolorkg.com/wp-content/uploads/2024/11/70029192.jpg',
    'category': ProductCategory.women,
    'subcategory': ProductSubcategory.downJackets,
    'description': 'Длинный двубортный пуховик, на застежке из кнопок, с двумя видами съемных шарфов. Первый шарф в виде манишки, по бокам есть отверстия для рук, и специальная теплая мягкая ткань,флис. Второй шарф , классический с отверстием для драпировки и фиксации. Со стороны спинки по низу расположена регулирую...',
    'sizes': ['S', 'M', 'L', 'XL'],
    'colors': ['Черный'],
  },
  {
    'id': 'women-040',
    'name': 'Длинный пуховик, оверсайз со съемным поясом',
    'price': 15990,
    'originalPrice': 24990,
    'imageUrl':
        'https://toolorkg.com/wp-content/uploads/2025/01/mmmmmmm89397608.webp',
    'category': ProductCategory.women,
    'subcategory': ProductSubcategory.downJackets,
    'description': 'Длинный пуховик, оверсайз со съемным поясом. По переду имеются карманы на магнитах. В правом кармане есть карабин на резинке, предназначенный для ключей, чтобы они не выпали. Внутренняя часть карманов из флиса, так же во внутренней части рукава имеются трикотажные манжеты, для более комфортной но...',
    'sizes': ['S', 'M', 'L', 'XL'],
    'colors': ['Петроль'],
  },
  {
    'id': 'women-041',
    'name': 'Удлиненный пуховик оверсайз с капюшоном',
    'price': 11990,
    'originalPrice': 18990,
    'imageUrl':
        'https://toolorkg.com/wp-content/uploads/2025/01/yayayayayayayayayayaya13367667.webp',
    'category': ProductCategory.women,
    'subcategory': ProductSubcategory.downJackets,
    'description': 'Удлиненный пуховик оверсайз, с объемным капюшоном. Форма напоминающая кокон не сковывает движения и сочетается как с юбкой так и с брюками. По задней части капюшона расположена резинка со стопором , для регулирования глубины. По внутренней части рукава имеются трикотажные манжеты, как дополнитель...',
    'sizes': ['S', 'M', 'L', 'XL'],
    'colors': ['Черный'],
  },
  {
    'id': 'women-042',
    'name': 'Удлиненный пуховик оверсайз с капюшоном',
    'price': 11990,
    'originalPrice': 18990,
    'imageUrl':
        'https://toolorkg.com/wp-content/uploads/2025/01/48796415.jpg',
    'category': ProductCategory.women,
    'subcategory': ProductSubcategory.downJackets,
    'description': 'Удлиненный пуховик оверсайз, с объемным капюшоном. Форма напоминающая кокон не сковывает движения и сочетается как с юбкой так и с брюками. По задней части капюшона расположена резинка со стопором , для регулирования глубины. По внутренней части рукава имеются трикотажные манжеты, как дополнитель...',
    'sizes': ['S', 'L', 'XL'],
    'colors': ['Петроль'],
  },
  {
    'id': 'women-043',
    'name': 'Женская вафельная рубашка',
    'price': 2799,
    'originalPrice': null,
    'imageUrl':
        'https://toolorkg.com/wp-content/uploads/2025/03/WhatsApp-Image-2025-03-07-at-08.38.55-5.jpeg',
    'category': ProductCategory.women,
    'subcategory': ProductSubcategory.shirts,
    'description': 'Весна на пороге: встречай переменчивую погоду в полной готовности !  Зима уходит, и впереди нас ждут теплые, но ветреные дни. В такой сезон особенно важно иметь в гардеробе легкую, но надежную защиту. Женская рубашка-ветровка — это идеальный баланс между стилем и функциональностью.  * Ветрозащитн...',
    'sizes': ['S', 'M', 'L', 'XL', 'XL'],
    'colors': ['Графит', 'Оливковый'],
  },
  {
    'id': 'women-044',
    'name': 'Женская водоотталкивающая рубашка',
    'price': 2799,
    'originalPrice': null,
    'imageUrl':
        'https://toolorkg.com/wp-content/uploads/2025/03/WhatsApp-Image-2025-03-07-at-08.38.24.jpeg',
    'category': ProductCategory.women,
    'subcategory': ProductSubcategory.shirts,
    'description': 'Женская рубашка с отложным воротником с застежкой на кнопках и накладными карманами на груди изготовлена из водоотталкивающего материала, что обеспечивает защиту от легких осадков. Кнопки застежки и карманы на груди добавляют практичности и удобства. Модный и универсальный стиль подходит для повс...',
    'sizes': ['XS', 'S', 'M', 'L', 'XL'],
    'colors': ['Графит', 'Кофе', 'Кремовый', 'Хаки'],
  },
  {
    'id': 'women-045',
    'name': 'Женская рубашка Сафари',
    'price': 2700,
    'originalPrice': null,
    'imageUrl':
        'https://toolorkg.com/wp-content/uploads/2025/06/DSC03320_resized.jpeg',
    'category': ProductCategory.women,
    'subcategory': ProductSubcategory.shirts,
    'description': 'Льняной комплект в стиле сафари — простота, которая работает на тебя. Лёгкая рубашка с коротким рукавом и шорты в тон создают цельный, но не перегруженный образ, идеально подходящий для тёплой погоды, путешествий и городской повседневности.  Рубашка: укороченный фасон с вырезами по бокам, отложно...',
    'sizes': ['S', 'M', 'L'],
    'colors': ['Бежевый', 'Кремовый'],
  },
  {
    'id': 'women-046',
    'name': 'Женская рубашка из коллекции "Wellness"',
    'price': 3000,
    'originalPrice': null,
    'imageUrl':
        'https://toolorkg.com/wp-content/uploads/2025/09/IMG_5589_resized.jpeg',
    'category': ProductCategory.women,
    'subcategory': ProductSubcategory.shirts,
    'description': 'Рубашка из коллекции Wellness. Лёгкость линий, мягкость ткани и свободный крой — как дыхание, как пауза в ритме города.  Она создана, чтобы дарить телу простор, а мыслям — спокойствие. В её простоте — гармония, в её минимализме — красота момента «здесь и сейчас».',
    'sizes': ['S', 'M', 'L', 'XL'],
    'colors': ['Белый', 'Голубой'],
  },
  {
    'id': 'women-047',
    'name': 'Женский кроп-свитер',
    'price': 3999,
    'originalPrice': null,
    'imageUrl':
        'https://toolorkg.com/wp-content/uploads/2025/03/WhatsApp-Image-2025-03-07-at-08.51.44-3.jpeg',
    'category': ProductCategory.women,
    'subcategory': ProductSubcategory.sweaters,
    'description': 'Женский кроп-свитер от Toolor — это отличный выбор для создания удобных и повседневных образов. Благодаря продуманному крою и качественной пряже, он станет незаменимым элементом гардероба в прохладные времена года.  Особенности: * Круглый воротник * Покрой реглан * Кроп-длина * Рукава и низ на ма...',
    'sizes': ['XS/S', 'M/L', 'XL/2XL'],
    'colors': ['Белый', 'Бордовый', 'Графит', 'Камель'],
  },
  {
    'id': 'women-048',
    'name': 'Женский свитер',
    'price': 3999,
    'originalPrice': null,
    'imageUrl':
        'https://toolorkg.com/wp-content/uploads/2024/12/Studio-Session-1566.JPG.jpg',
    'category': ProductCategory.women,
    'subcategory': ProductSubcategory.sweaters,
    'description': 'Этот теплый свитер выполнен из турецкой хлопковой пряжи с продуманной линией плеча и аккуратным воротником, обеспечивая комфорт и мягкость на ощупь в прохладное время года.  Особенности: * Круглый воротник * Рукава и низ на манжете * Длина до бедер * Свободный силуэт * Гипоаллергенная турецкая пр...',
    'sizes': ['XS/S', 'M/L', 'XL/2XL'],
    'colors': ['Бежевый', 'Оливковый', 'Серый', 'Темно-синий'],
  },
  {
    'id': 'women-049',
    'name': 'Женский свитер "Ала-Тоо"',
    'price': 3999,
    'originalPrice': null,
    'imageUrl':
        'https://toolorkg.com/wp-content/uploads/2025/01/10.01.2025-23_44_10.png',
    'category': ProductCategory.women,
    'subcategory': ProductSubcategory.sweaters,
    'description': 'Вязаный свитер «Ала-Тоо» - это современное воплощение теплых воспоминаний о бабушкиных вязанных изделиях, которые согревали нас с детства. Иллюстрацию для свитера разработала талантливая художница Асия Талип. На ней изображены символы нашей страны: величественные горы, облака, реки, спускающиеся ...',
    'sizes': ['XS/S', 'M/L', 'XL/2XL'],
    'colors': ['Бордовый', 'Голубой', 'Красный'],
  },
  {
    'id': 'women-050',
    'name': 'Женские спортивные брюки',
    'price': 3250,
    'originalPrice': null,
    'imageUrl':
        'https://toolorkg.com/wp-content/uploads/2024/12/0F2A0309.jpg',
    'category': ProductCategory.women,
    'subcategory': ProductSubcategory.sweatshirts,
    'description': 'Женская спортивная двойка свитшот-брюки с фирменным силуэтом и со встренными потайными карманами.  Особенности: * Потайные карманы на  на брюках * Свободный силуэт * Лакончный принт лого и рунической надписи «Кочевники будущего»',
    'sizes': ['XS', 'S', 'M', 'L', 'XL'],
    'colors': ['Айвори', 'Бежевый', 'Графит'],
  },
  {
    'id': 'women-051',
    'name': 'Женский свитшот',
    'price': 3250,
    'originalPrice': null,
    'imageUrl':
        'https://toolorkg.com/wp-content/uploads/2024/12/0F2A0498.jpg',
    'category': ProductCategory.women,
    'subcategory': ProductSubcategory.sweatshirts,
    'description': 'Женская спортивная двойка свитшот-брюки встроенными потайными карманами.  Особенности: *Круглый вырез воротника * Потайные карманы на свитшоте и на брюках * Свободный фасон * Лаконичный принт лого и рунической надписи «Кочевники будущего»',
    'sizes': ['XS', 'S', 'M', 'L', 'XL'],
    'colors': ['Айвори', 'Бежевый', 'Графит'],
  },
  {
    'id': 'women-052',
    'name': 'Женский свитшот полузамок "Wellness"',
    'price': 3999,
    'originalPrice': null,
    'imageUrl':
        'https://toolorkg.com/wp-content/uploads/2025/09/IMG_5598_resized.jpeg',
    'category': ProductCategory.women,
    'subcategory': ProductSubcategory.sweatshirts,
    'description': 'Велнес — новый стиль, утверждающий концепцию здорового образа жизни, основанного на физическом и ментальном здоровье, отказе от вредных привычек, здоровом питании и физических упражнений для поддержания формы.  Жен. свитшот полузамок  Особенности: *Свободный фасон *Втачные спущенные рукава *Накла...',
    'sizes': ['S/M', 'M/L'],
    'colors': ['Белый', 'Темно-синий'],
  },
  {
    'id': 'women-053',
    'name': 'Женский свитшот-двойка',
    'price': 3400,
    'originalPrice': null,
    'imageUrl':
        'https://toolorkg.com/wp-content/uploads/2024/12/0F2A0479.jpg',
    'category': ProductCategory.women,
    'subcategory': ProductSubcategory.sweatshirts,
    'description': 'Женская спортивная в тоже время утонченная двойка свитшот-брюки для вашего акцентного образа.  Особенности: *Круглый вырез воротника * Брюки с карманами * Свободный фасон * Вареный эффект ткани * Лаконичный принт лого и рунической надписи «Кочевники будущего»',
    'sizes': ['XS', 'S', 'M', 'L', 'XL'],
    'colors': ['Айвори', 'Бежевый', 'Графит'],
  },
  {
    'id': 'women-054',
    'name': 'Женский полутренч',
    'price': 8500,
    'originalPrice': null,
    'imageUrl':
        'https://toolorkg.com/wp-content/uploads/2025/10/bezhevaya-vetrovka-scaled.jpg',
    'category': ProductCategory.women,
    'subcategory': ProductSubcategory.trench,
    'description': 'Куртка из коллекции «Сандыκ»  Она словно сундук предков — хранит в себе тайные знаки и линии, что веками сопровождали кочевников в их пути. Орнамент, разложенный в композицию, — это не просто узор, а язык символов: здесь звучат песни гор, дыхание степей и мудрость рода.  Съемный капюшон-косынка и...',
    'sizes': ['S', 'M', 'L', 'XL'],
    'colors': ['Бежевый', 'Кофе', 'Темно-синий'],
  },
  {
    'id': 'women-055',
    'name': 'Женская футболка',
    'price': 1599,
    'originalPrice': null,
    'imageUrl':
        'https://toolorkg.com/wp-content/uploads/2024/12/0F2A1270.jpg',
    'category': ProductCategory.women,
    'subcategory': ProductSubcategory.tshirts,
    'description': 'Классическая женская футболка выполнена из мягкой хлопковой ткани, дополнена брендированной минималистичной вышивкой для простых, но всегда актуальных повседневных образов. Вдохновлено культурой номадов.  Особенности: *Круглый вырез воротника *Втачные короткие рукава *С минималистичной вышивкой р...',
    'sizes': ['XS', 'S', 'M', 'L'],
    'colors': ['Бежевый', 'Графит', 'Серый меланж'],
  },
  {
    'id': 'women-056',
    'name': 'Женская футболка Оверсайз с вышивкой',
    'price': 1990,
    'originalPrice': null,
    'imageUrl':
        'https://toolorkg.com/wp-content/uploads/2024/12/6P3A1531.jpg',
    'category': ProductCategory.women,
    'subcategory': ProductSubcategory.tshirts,
    'description': 'Культура номада несет с собой свободную, заявляющую форму, как и наша женская oversize футболка, изготовленая из хлопка, сочетает в себе комфорт и стиль в одном изделии.  Особенности: *Круглый вырез воротника *Втачные спущенные рукава *Oversize * Экологически безврредный принт *Представлена в дву...',
    'sizes': ['XS', 'S', 'M', 'L'],
    'colors': ['Айвори', 'Пепельный', 'Темно-синий'],
  },
  {
    'id': 'women-057',
    'name': 'Женская футболка Оверсайз с принтом',
    'price': 1990,
    'originalPrice': null,
    'imageUrl':
        'https://toolorkg.com/wp-content/uploads/2024/12/6P3A1700.jpg',
    'category': ProductCategory.women,
    'subcategory': ProductSubcategory.tshirts,
    'description': 'Культура номада несет с собой свободную, заявляющую форму, как и наша женская oversize футболка, изготовленая из хлопка, сочетает в себе комфорт и стиль в одном изделии.  Особенности: *Круглый вырез воротника *Втачные спущенные рукава *Oversize * Экологически безврредный принт *Представлена в дву...',
    'sizes': ['XS', 'S', 'M', 'L'],
    'colors': ['Белый', 'Оливковый', 'Черный'],
  },
  {
    'id': 'women-058',
    'name': 'Женская футболка Юрта',
    'price': 1599,
    'originalPrice': null,
    'imageUrl':
        'https://toolorkg.com/wp-content/uploads/2024/12/Studio-Session-141.jpg',
    'category': ProductCategory.women,
    'subcategory': ProductSubcategory.tshirts,
    'description': 'Форма, линия, акцент. Футболка "Юрта" от Toolor олицетворяет уют и дом, который всегда с вами. Вдохновлена ​​кочевым образом жизни и обеспечивает чувство свободы и комфорта. Особенности: *Круглый вырез воротника *Втачные короткие рукава * Рельефные швы * Брендирование вышивкой рунической надписи ...',
    'sizes': ['XS', 'S', 'M', 'L'],
    'colors': ['Айвори', 'Серый', 'Черный'],
  },
  {
    'id': 'women-059',
    'name': 'Женская футболка реглан с вышивкой',
    'price': 1990,
    'originalPrice': null,
    'imageUrl':
        'https://toolorkg.com/wp-content/uploads/2024/12/6P3A1464.pdf.jpg',
    'category': ProductCategory.women,
    'subcategory': ProductSubcategory.tshirts,
    'description': 'Женская oversize футболка из хлопка. Функционально идентичен обычной футболке, но дополнен авторской работой объединяющий культурно-житейский уклад кочевников в современной интерпретации. Вдохновлено свободным Кыргызским народом.  Особенности: *Круглый вырез воротника *Рукава реглан *Оversize * Э...',
    'sizes': ['XS', 'S', 'M', 'L'],
    'colors': ['Айвори', 'Бежевый', 'Черный'],
  },
  {
    'id': 'women-060',
    'name': 'Женская футболка-варенка',
    'price': 2800,
    'originalPrice': null,
    'imageUrl':
        'https://toolorkg.com/wp-content/uploads/2025/05/0F2A5475.jpg',
    'category': ProductCategory.women,
    'subcategory': ProductSubcategory.tshirts,
    'description': 'Как капля краски в потоке повседневности - женская оверсайз футболка с вареным эффектом привлекает с первого взгляда. Уникальный окрас, полученный в результате специальной обработки, делает каждую футболку неповторимой. Мягкий хлопковый трикотаж нежно ложится по телу, а свободный крой подчеркивае...',
    'sizes': ['S', 'M', 'L', 'XL'],
    'colors': ['Графит', 'Фиолетовый'],
  },
  {
    'id': 'women-061',
    'name': 'Женская футболка-варенка реглан',
    'price': 2800,
    'originalPrice': null,
    'imageUrl':
        'https://toolorkg.com/wp-content/uploads/2025/05/0F2A5510-e1748475413920.jpg',
    'category': ProductCategory.women,
    'subcategory': ProductSubcategory.tshirts,
    'description': 'Как капля краски в потоке повседневности - женская оверсайз футболка с вареным эффектом привлекает с первого взгляда. Уникальный окрас, полученный в результате специальной обработки, делает каждую футболку неповторимой. Мягкий хлопковый трикотаж нежно ложится по телу, а свободный крой подчеркивае...',
    'sizes': ['S', 'M', 'L', 'XL'],
    'colors': ['Голубой', 'Графит'],
  },
  {
    'id': 'women-062',
    'name': 'Женский Худи двойка',
    'price': 3600,
    'originalPrice': null,
    'imageUrl':
        'https://toolorkg.com/wp-content/uploads/2024/12/0F2A0747.jpg',
    'category': ProductCategory.women,
    'subcategory': ProductSubcategory.hoodies,
    'description': 'Женская спортивная двойка худи-брюки с фирменным силуэтом и со встроенными потайными карманами.  Особенности: *Капюшон на шнуровке * Потайные карманы на свитшоте и на брюках * Свободный силуэт * Декоративная вышивка лого и рунической надписи «Кочевники будущего»',
    'sizes': ['XS/S', 'S/M', 'M/L'],
    'colors': ['Айвори', 'Бежевый', 'Графит', 'Розовый'],
  },
  // =========================================================================
  // МУЖЧИНАМ
  // =========================================================================
  {
    'id': 'men-001',
    'name': 'Мужские брюки',
    'price': 3600,
    'originalPrice': null,
    'imageUrl':
        'https://toolorkg.com/wp-content/uploads/2024/12/0F2A7401-1-1.jpg',
    'category': ProductCategory.men,
    'subcategory': ProductSubcategory.pants,
    'description': 'Этот комплект, состоящий из худи с капюшоном и брюк, выполнен в минималистичном стиле и станет удобным, а также стильным дополнением вашего гардероба. На ткани — вышивка с логотипом и слоганом «Кочевники будущего», который выполнен в тон к ткани.  Особенность худи — юрты встроенного силуэта, выпо...',
    'sizes': ['S/M', 'M/L', 'L/XL'],
    'colors': ['Кармеланж', 'Темно-зеленый', 'Темно-синий', 'Черный'],
  },
  {
    'id': 'men-002',
    'name': 'Мужские брюки',
    'price': 4100,
    'originalPrice': null,
    'imageUrl':
        'https://toolorkg.com/wp-content/uploads/2025/03/WhatsApp-Image-2025-03-07-at-11.35.21.jpeg',
    'category': ProductCategory.men,
    'subcategory': ProductSubcategory.pants,
    'description': 'Брюки в стиле милитари – классика с акцентом на функциональность !  * Классический крой с тактическими элементами – строгий силуэт с удобными деталями. * Функциональные карманы – молнии и накладные карманы для необходимых мелочей. * Комфортная посадка – пояс на резинке, а спереди –на кнопке.  Иде...',
    'sizes': ['S', 'M', 'L', 'XL', 'XXL'],
    'colors': ['Бежевый', 'Хаки', 'Черный'],
  },
  {
    'id': 'men-003',
    'name': 'Мужские брюки',
    'price': 3400,
    'originalPrice': null,
    'imageUrl':
        'https://toolorkg.com/wp-content/uploads/2024/12/0F2A7919-1.jpg',
    'category': ProductCategory.men,
    'subcategory': ProductSubcategory.pants,
    'description': 'Мужская двойка свитшот-брюки из ткани «Lining» с ярким дизайном вышивки, вдохновленным силуэтом "Тундука" юрты, станет ярким дополнением вашего гардероба.  Особенности: *Круглый вырез воротника * Конструктивные рельефы, подчеркивающие силуэт юрты * Лаконичная вышивка с силуэтом "Тундука" юрты и р...',
    'sizes': ['S', 'M', 'L', 'XL', 'XXL'],
    'colors': ['Графит', 'Коричневый', 'Темно-синий', 'Хаки'],
  },
  {
    'id': 'men-004',
    'name': 'Мужские вафельные брюки',
    'price': 4100,
    'originalPrice': null,
    'imageUrl':
        'https://toolorkg.com/wp-content/uploads/2025/03/WhatsApp-Image-2025-03-07-at-11.35.52.jpeg',
    'category': ProductCategory.men,
    'subcategory': ProductSubcategory.pants,
    'description': 'Брюки в стиле джоггеров – удобство и свобода движений !  * Расслабленный силуэт с манжетами – комфорт и фиксация ноги. * Накладные «портфельные» карманы – вместительные, удобные, добавляют характер. * Эластичный пояс – резинка сзади и по бокам для комфортной посадки.  Этот вариант для тех, кто вы...',
    'sizes': ['S', 'M', 'L', 'XL', 'XXL'],
    'colors': ['Бежевый', 'Хаки', 'Черный'],
  },
  {
    'id': 'men-005',
    'name': 'Мужские спортивные брюки',
    'price': 3600,
    'originalPrice': null,
    'imageUrl':
        'https://toolorkg.com/wp-content/uploads/2025/09/DSC05063_resized.jpeg',
    'category': ProductCategory.men,
    'subcategory': ProductSubcategory.pants,
    'description': 'Худи-балаклава и брюки из трёхнитки — не просто комплект, а форма современного воина.  В городской среде он даёт свободу движения. На природе — защищает и становится частью ритма земли.  На спинке — древний орнамент Буркут в виде печати. Это знак силы, высоты и несломленного духа. Птица, что века...',
    'sizes': ['M', 'L', 'XL'],
    'colors': ['Графит', 'Черный'],
  },
  {
    'id': 'men-006',
    'name': 'Мужские спортивные брюки',
    'price': 3599,
    'originalPrice': null,
    'imageUrl':
        'https://toolorkg.com/wp-content/uploads/2024/12/0F2A7098-1.jpg',
    'category': ProductCategory.men,
    'subcategory': ProductSubcategory.pants,
    'description': 'Мужская спортивная двойка свитшот-брюки, которая так же подойдет для повседневной жизни.  Особенности: * Свободный силуэт свитшота и брюк * Удобные и практичные брюки для вашего гардероба»',
    'sizes': ['S', 'M', 'L', 'XL'],
    'colors': ['Кармеланж', 'Темно-зеленый', 'Темно-синий', 'Черный'],
  },
  {
    'id': 'men-007',
    'name': 'Мужские шерстяные брюки',
    'price': 3499,
    'originalPrice': null,
    'imageUrl':
        'https://toolorkg.com/wp-content/uploads/2025/11/blizhe-shatny-scaled.jpg',
    'category': ProductCategory.men,
    'subcategory': ProductSubcategory.pants,
    'description': 'Мужские шерстяные брюки из коллекции Wellness. Строгие линии, глубокий цвет, сдержанный ритм — здесь минимализм встречается с элегантностью.  Тонкая шерсть обнимает лёгкостью и теплом, а классический силуэт придаёт уверенность в каждом движении.  Эти брюки — о внутреннем спокойствии, о гармонии ф...',
    'sizes': ['M', 'L', 'XL', 'XXL', '3XL'],
    'colors': ['Коричневый', 'Темно-зеленый'],
  },
  {
    'id': 'men-008',
    'name': 'Мужская ветровка с капюшоном',
    'price': 4000,
    'originalPrice': null,
    'imageUrl':
        'https://toolorkg.com/wp-content/uploads/2025/05/0F2A8131-1.jpg',
    'category': ProductCategory.men,
    'subcategory': ProductSubcategory.windbreakers,
    'description': 'Легкая и практичная мужская ветровка, созданная для комфорта в условиях городской активности и переменчивой погоды. Модель выполнена из прочной ветрозащитной ткани с водоотталкивающей пропиткой, что обеспечивает надежную защиту от ветра и дождя. Преимущество изделия - продуманная система функцион...',
    'sizes': ['S', 'M', 'L', 'XL', 'XXL'],
    'colors': ['Графит', 'Черный'],
  },
  {
    'id': 'men-009',
    'name': 'Мужская водолазка',
    'price': 4499,
    'originalPrice': null,
    'imageUrl':
        'https://toolorkg.com/wp-content/uploads/2024/12/0F2A8401-1.jpg',
    'category': ProductCategory.men,
    'subcategory': ProductSubcategory.turtlenecks,
    'description': 'Водолазка с высоким воротником от Toolor выполнен из гипоаллергенной пряжи высокого качества. Продуманный крой с плавной линией плеча и аккуратной брендированной вышивкой делает его идеальным дополнением для уютных повседневных образов.  Особенности: * Высокий воротник * Рукава и низ на манжете *...',
    'sizes': ['XS/S', 'M/L', 'XL/2XL'],
    'colors': ['Айвори', 'Графит', 'Светло-бежевый', 'Синий'],
  },
  {
    'id': 'men-010',
    'name': 'Мужской вязанный полузамок',
    'price': 4999,
    'originalPrice': null,
    'imageUrl':
        'https://toolorkg.com/wp-content/uploads/2024/12/0F2A8508-1.jpg',
    'category': ProductCategory.men,
    'subcategory': ProductSubcategory.turtlenecks,
    'description': 'Мужской полузамок с высоким воротником был изготовлен из гипоалергенной хлопковой пряжи высокого качества. Продуманный крой с плавной линией плеча и аккуратной брендированной вышивкой делает его идеальным дополнением для уютных повседневных образов.  Особенности: * Высокий воротник * Рукава и низ...',
    'sizes': ['XS/S', 'M/L', 'XL/2XL'],
    'colors': ['Айвори', 'Камель', 'Серый', 'Черный'],
  },
  {
    'id': 'men-011',
    'name': 'Мужской кардиган',
    'price': 4999,
    'originalPrice': null,
    'imageUrl':
        'https://toolorkg.com/wp-content/uploads/2024/12/0F2A8107-1.jpg',
    'category': ProductCategory.men,
    'subcategory': ProductSubcategory.cardigans,
    'description': 'Мужской кардиган с тесьмой выполнен из высококачественной хлопковой пряжи, обеспечивающий комфорт и долговечность. Классический фасон с застёжкой на молнии обеспечит вам универсальность в сочетании с деловой и повседневной одеждой.  Особенности: *Воротник стойка *Манжеты на рукавах и по низу *Мол...',
    'sizes': ['XS/S', 'M/L', 'XL/2XL'],
    'colors': ['Голубой', 'Коричневый', 'Серый', 'Черный'],
  },
  {
    'id': 'men-012',
    'name': 'Короткая куртка',
    'price': 13990,
    'originalPrice': 21990,
    'imageUrl':
        'https://toolorkg.com/wp-content/uploads/2025/01/76289074.jpg',
    'category': ProductCategory.men,
    'subcategory': ProductSubcategory.jackets,
    'description': 'Мужская куртка свободного силуэта. Одна расцветка полностью черная , вторая серо-черная . Капюшон несъемный, с планкой которую можно носить как в закрытом так и открытом положении в качестве дополнительного козырька к капюшону. В зоне плеч погоны на кнопках. Слева в области груди расположен кар...',
    'sizes': ['S', 'M', 'L', 'XL'],
    'colors': ['Темно-серый'],
  },
  {
    'id': 'men-013',
    'name': 'Короткая куртка с капюшоном',
    'price': 10990,
    'originalPrice': 16990,
    'imageUrl':
        'https://toolorkg.com/wp-content/uploads/2025/01/34877265-1.webp',
    'category': ProductCategory.men,
    'subcategory': ProductSubcategory.jackets,
    'description': 'Короткая мужская куртка с отстегивающимся капюшоном. Куртку можно носить как с капюшоном так и без него. На капюшон есть пата, регулирующая длину и у лица резинка со стопором для регулирования степени прилегания. По переду два кармана на магнитах, это очень удобная застежка. В правом кармане кара...',
    'sizes': ['S', 'M', 'L'],
    'colors': ['Петроль'],
  },
  {
    'id': 'men-014',
    'name': 'Короткая куртка с капюшоном',
    'price': 13990,
    'originalPrice': 21990,
    'imageUrl':
        'https://toolorkg.com/wp-content/uploads/2025/01/30558597.webp',
    'category': ProductCategory.men,
    'subcategory': ProductSubcategory.jackets,
    'description': 'Мужская куртка свободного силуэта. Одна расцветка полностью черная , вторая серо-черная . Капюшон несъемный, с планкой которую можно носить как в закрытом так и открытом положении в качестве дополнительного козырька к капюшону. В зоне плеч погоны на кнопках. Слева в области груди расположен кар...',
    'sizes': ['S', 'M', 'L', 'XL'],
    'colors': ['Черный'],
  },
  {
    'id': 'men-015',
    'name': 'Короткая куртка с капюшоном',
    'price': 10990,
    'originalPrice': 16990,
    'imageUrl':
        'https://toolorkg.com/wp-content/uploads/2025/01/59775982.webp',
    'category': ProductCategory.men,
    'subcategory': ProductSubcategory.jackets,
    'description': 'Короткая мужская куртка с отстегивающимся капюшоном. Куртку можно носить как с капюшоном так и без него. На капюшон есть пата, регулирующая длину и у лица резинка со стопором для регулирования степени прилегания. По переду два кармана на магнитах, это очень удобная застежка. В правом кармане кара...',
    'sizes': ['S', 'M', 'L', 'XL'],
    'colors': ['Черный'],
  },
  {
    'id': 'men-016',
    'name': 'Мужская ветровка из коллекции "Wellness"',
    'price': 6500,
    'originalPrice': null,
    'imageUrl':
        'https://toolorkg.com/wp-content/uploads/2025/09/DSC00781_4MdGZE0izp_resized.jpeg',
    'category': ProductCategory.men,
    'subcategory': ProductSubcategory.jackets,
    'description': 'Он создан для тех, кто идёт своей дорогой — по улицам города или тропам в горах. Мужская куртка из коллекции “Сандык” — это современный щит, в котором сплелись традиция и функциональность.  Водоотталкивающая плащёвка с хлопком и полиэстером бережёт от ветра и дождя.  Чистые линии и однотонная пал...',
    'sizes': ['M', 'L', 'XL', 'XXL', '3XL'],
    'colors': ['Темно-синий', 'Черный'],
  },
  {
    'id': 'men-017',
    'name': 'Мужская двухсторонняя куртка',
    'price': 9000,
    'originalPrice': null,
    'imageUrl':
        'https://toolorkg.com/wp-content/uploads/2025/03/WhatsApp-Image-2025-03-07-at-11.24.30.jpeg',
    'category': ProductCategory.men,
    'subcategory': ProductSubcategory.jackets,
    'description': '• Водонепроницаемость 5000 мм / паропроницаемость 1500 мм • Защита от ветра • Двусторонняя носка • Молния SBS • Рукава с регулируемыми манжетами • Съёмный капюшон • Водонепроницаемая молния • Водоотталкивающая ткань',
    'sizes': ['L'],
    'colors': ['Серый', 'Синий'],
  },
  {
    'id': 'men-018',
    'name': 'Мужская замшевая куртка из коллекции "Сандык"',
    'price': 9000,
    'originalPrice': null,
    'imageUrl':
        'https://toolorkg.com/wp-content/uploads/2025/09/zamshevaya-kurtka-scaled.jpg',
    'category': ProductCategory.men,
    'subcategory': ProductSubcategory.jackets,
    'description': 'Эта куртка из коллекци "Сандык"— больше, чем одежда. Ткань с мягкой текстурой замши хранит тепло земли и силу ветра. На её спинке — силуэт беркута, птицы, что веками была символом кочевников.  Беркут расправляет крылья в небе, соединяя горы и степи, прошлое и будущее. Его образ в кокетке напомина...',
    'sizes': ['M', 'L', 'XL', 'XXL', '3XL'],
    'colors': ['Коричневый'],
  },
  {
    'id': 'men-019',
    'name': 'Мужская куртка с наполнителем',
    'price': 12000,
    'originalPrice': null,
    'imageUrl':
        'https://toolorkg.com/wp-content/uploads/2025/03/WhatsApp-Image-2025-03-07-at-11.36.21-1.jpeg',
    'category': ProductCategory.men,
    'subcategory': ProductSubcategory.jackets,
    'description': '*Утепленная куртка с защитой от ветра для комфортной носки*  Эта куртка разработана с учётом всех современных требований к функциональности. Сочетая отличную защиту от внешних факторов и высокий уровень комфорта, она станет незаменимым элементом в вашем гардеробе для прохладных и ветреных дней. *...',
    'sizes': ['L', 'XL'],
    'colors': ['Черный'],
  },
  {
    'id': 'men-020',
    'name': 'Стеганный лайтдаун',
    'price': 6990,
    'originalPrice': null,
    'imageUrl':
        'https://toolorkg.com/wp-content/uploads/2024/11/33715943.jpg.webp',
    'category': ProductCategory.men,
    'subcategory': ProductSubcategory.lightdown,
    'description': 'Легкий стеганный лайтдаун—это легкая курточка которую можно поддеть под плащи куртки, жилеты и зимние пуховики, для дополнительного утепления. Застегивается на кнопках, по переду есть два кармана, так же внутри куртки есть карман со стопором и ремешками, в который можно завернуть куртку и носить ...',
    'sizes': ['S', 'M', 'L', 'XL'],
    'colors': ['Светло-зеленый', 'Черный'],
  },
  {
    'id': 'men-021',
    'name': 'Мужской лонгслив',
    'price': 2550,
    'originalPrice': null,
    'imageUrl':
        'https://toolorkg.com/wp-content/uploads/2024/12/0F2A9098-1.jpg',
    'category': ProductCategory.men,
    'subcategory': ProductSubcategory.longsleeves,
    'description': 'Мужской лонгслив c дополнительными вставочными рукавами выполнен в покрое реглан с декоративной тамбурной вышивкой. Вдохновлено культурой номадов.  Особенности: *Круглый вырез воротника *Дополнительные вствки на рукавах *Рукава реглан *Оversize *Представлена в двух вариантах: 1) Вышивка с логотип...',
    'sizes': ['S', 'M', 'L', 'XL'],
    'colors': ['Голубой', 'Кремовый', 'Темно-зеленый', 'Темно-синий'],
  },
  {
    'id': 'men-022',
    'name': 'Мужской лонгслив с вышивкой',
    'price': 2550,
    'originalPrice': null,
    'imageUrl':
        'https://toolorkg.com/wp-content/uploads/2024/12/0F2A8919-1.jpg',
    'category': ProductCategory.men,
    'subcategory': ProductSubcategory.longsleeves,
    'description': 'Мужской oversize лонгслив для стильного дополнения вашего гардероба.  Особенности: *Круглый вырез воротника *Втачные спущенные рукава *Oversize * Экологически безвредный принт *Представлена в двух вариантах: 1) Вышивка лого спереди и руническая надпись « Кочевники будущего» на спинке 2) Эксклюзив...',
    'sizes': ['S', 'M', 'L', 'XL'],
    'colors': ['Бордовый', 'Темно-синий', 'Черный'],
  },
  {
    'id': 'men-023',
    'name': 'Мужской лонгслив с принтом',
    'price': 2550,
    'originalPrice': null,
    'imageUrl':
        'https://toolorkg.com/wp-content/uploads/2024/12/0F2A8868-1.jpg',
    'category': ProductCategory.men,
    'subcategory': ProductSubcategory.longsleeves,
    'description': 'Мужской oversize лонгслив для стильного дополнения вашего гардероба.  Особенности: *Круглый вырез воротника *Втачные спущенные рукава *Oversize * Экологически безвредный принт *Представлена в двух вариантах: 1) Вышивка лого спереди и руническая надпись « Кочевники будущего» на спинке 2) Эксклюзив...',
    'sizes': ['S', 'M', 'L', 'XL'],
    'colors': ['Айвори', 'Голубой', 'Серый меланж'],
  },
  {
    'id': 'men-024',
    'name': 'Мужской лонгслив с принтом',
    'price': 2550,
    'originalPrice': null,
    'imageUrl':
        'https://toolorkg.com/wp-content/uploads/2024/12/0F2A8946-1.jpg',
    'category': ProductCategory.men,
    'subcategory': ProductSubcategory.longsleeves,
    'description': 'Мужкой оверсайз лонгслив с контрастными рукавами и монохромным этно-принтом.  Особенности: *Круглый вырез воротника *Контрасные рукава реглан *Оversize * Экологически безврредный принт *Уникальный этно-принт с авторской иллюстрацией Асии Талип, изображающий быт кочевого народа.',
    'sizes': ['S', 'M', 'L', 'XL'],
    'colors': ['Голубой', 'Темно-зеленый', 'Темно-синий'],
  },
  {
    'id': 'men-025',
    'name': 'Длинный пуховик с капюшоном',
    'price': 13990,
    'originalPrice': 21990,
    'imageUrl':
        'https://toolorkg.com/wp-content/uploads/2024/12/97609014.webp',
    'category': ProductCategory.men,
    'subcategory': ProductSubcategory.downJackets,
    'description': 'Длинный мужской пуховик, с отстегивающимся капюшоном. Куртку можно носить как с капюшоном так и без него. На капюшон есть пата, регулирующая длину и у лица резинка со стопором для регулирования степени прилегания. По переду два кармана на магнитах, это очень удобная застежка. В правом кармане кар...',
    'sizes': ['S', 'M', 'L', 'XL'],
    'colors': [],
  },
  {
    'id': 'men-026',
    'name': 'Удлиненный мужской пуховик',
    'price': 11990,
    'originalPrice': 18990,
    'imageUrl':
        'https://toolorkg.com/wp-content/uploads/2025/01/31420863.jpg',
    'category': ProductCategory.men,
    'subcategory': ProductSubcategory.downJackets,
    'description': 'Удлиненный мужской пуховик , с отстегивающимся капюшоном. Куртку можно носить как с капюшоном так и без него. По переду два утепленных кармана для удобства сложить руки , по талии резинка со стопором , которую можно затянув изменить силуэт прямого в прилегающий. На капюшон есть пата, регулирующая...',
    'sizes': ['S', 'M', 'L', 'XL'],
    'colors': ['Черный'],
  },
  {
    'id': 'men-027',
    'name': 'Удлиненный мужской пуховик',
    'price': 11990,
    'originalPrice': 18990,
    'imageUrl':
        'https://toolorkg.com/wp-content/uploads/2024/11/35837431.jpg.webp',
    'category': ProductCategory.men,
    'subcategory': ProductSubcategory.downJackets,
    'description': 'Удлиненный мужской пуховик , с отстегивающимся капюшоном. Куртку можно носить как с капюшоном так и без него. По переду два утепленных кармана для удобства сложить руки , по талии резинка со стопором , которую можно затянув изменить силуэт прямого в прилегающий. На капюшон есть пата, регулирующая...',
    'sizes': ['S', 'M', 'L', 'XL'],
    'colors': ['Синий'],
  },
  {
    'id': 'men-028',
    'name': 'Мужская вафельная рубашка',
    'price': 4100,
    'originalPrice': null,
    'imageUrl':
        'https://toolorkg.com/wp-content/uploads/2025/03/WhatsApp-Image-2025-03-07-at-11.34.32-1.jpeg',
    'category': ProductCategory.men,
    'subcategory': ProductSubcategory.shirts,
    'description': 'Мужская вафельная рубашка  Особенности: *Классический посадка *Фирменная конструкция силуэт Юрты *Застежка на молнии *Отложной воротник *2 нагрудных кармана в стиле "Милитари" и 2 потайных кармана для рук на молнии *Рукава на мажете с регулируемой застежкой на кнопках *Декоративная ключница с фир...',
    'sizes': ['S', 'M', 'L', 'XL', 'XXL'],
    'colors': ['Бежевый', 'Хаки', 'Черный'],
  },
  {
    'id': 'men-029',
    'name': 'Мужская рубашка',
    'price': 2799,
    'originalPrice': null,
    'imageUrl':
        'https://toolorkg.com/wp-content/uploads/2025/03/WhatsApp-Image-2025-03-07-at-11.34.07-1.jpeg',
    'category': ProductCategory.men,
    'subcategory': ProductSubcategory.shirts,
    'description': 'Мужская рубашка с отложным воротником с застежкой на кнопках и накладными карманами на груди изготовлена из водоотталкивающего материала, что обеспечивает защиту от легких осадков. Кнопки застежки и карманы на груди добавляют практичности и удобства. Модный и универсальный стиль подходит для повс...',
    'sizes': ['S', 'M', 'L', 'XL'],
    'colors': ['Серый', 'Фисташковый', 'Хаки'],
  },
  {
    'id': 'men-030',
    'name': 'Мужской свитер',
    'price': 3999,
    'originalPrice': null,
    'imageUrl':
        'https://toolorkg.com/wp-content/uploads/2024/12/0F2A8846-1.jpg',
    'category': ProductCategory.men,
    'subcategory': ProductSubcategory.sweaters,
    'description': 'Этот теплый свитер выполнен из турецкой хлопковой пряжи с продуманной линией плеча и аккуратным воротником, обеспечивая комфорт и мягкость на ощупь в прохладное время года.  Особенности: * Круглый воротник * Рукава и низ на манжете * Длина до бедер * Свободный силуэт * Гипоаллергенная турецкая пр...',
    'sizes': ['XS/S', 'M/L', 'XL/2XL'],
    'colors': ['Айвори', 'Винный', 'Светло-бежевый', 'Серый', 'Темно-синий'],
  },
  {
    'id': 'men-031',
    'name': 'Мужской полузамок',
    'price': 2499,
    'originalPrice': null,
    'imageUrl':
        'https://toolorkg.com/wp-content/uploads/2024/12/0F2A7824-1.jpg',
    'category': ProductCategory.men,
    'subcategory': ProductSubcategory.sweatshirts,
    'description': 'Мужской свитшот с воротником на замке отличный выбор утепленного второго слоя.  Особенности: * Воротник стойка на молнии * Мягкий бамбуковый начес * Лаконичный принт лого',
    'sizes': ['S', 'M', 'L', 'XL'],
    'colors': ['Графит', 'Светло-бежевый', 'Черный'],
  },
  {
    'id': 'men-032',
    'name': 'Мужской свитшот',
    'price': 3400,
    'originalPrice': null,
    'imageUrl':
        'https://toolorkg.com/wp-content/uploads/2024/12/0F2A7536-1.jpg',
    'category': ProductCategory.men,
    'subcategory': ProductSubcategory.sweatshirts,
    'description': 'Мужская двойка свитшот-брюки из ткани с ярким дизайном вышивки, вдохновленным элементом юрты "Тундук", станет ярким дополнением вашего гардероба.  Особенности: *Круглый вырез воротника * Брюки с карманами * Конструктивные рельефы, подчеркивающие силуэт юрты * Свободный фасон * Лаконичная вышивка ...',
    'sizes': ['S', 'M', 'L', 'XL', 'XXL'],
    'colors': ['Графит', 'Коричневый', 'Темно-синий', 'Хаки'],
  },
  {
    'id': 'men-033',
    'name': 'Мужской свитшот-брюки',
    'price': 3400,
    'originalPrice': null,
    'imageUrl':
        'https://toolorkg.com/wp-content/uploads/2024/12/0F2A6969.jpg',
    'category': ProductCategory.men,
    'subcategory': ProductSubcategory.sweatshirts,
    'description': 'Мужская спортивная двойка свитшот-брюки, которая так же отлично подойдет для активного отдыха.  Особенности: *Круглый вырез воротника * Брюки с карманами * Свободный фасон * Вареный эффект ткани * Лакончный принт лого спереди свитшота и руническая надпись «Кочевники будущего» на спинке',
    'sizes': ['S', 'M', 'L', 'XL'],
    'colors': ['Кармеланж', 'Темно-зеленый', 'Темно-синий', 'Черный'],
  },
  {
    'id': 'men-034',
    'name': 'Мужская флисовая куртка',
    'price': 4500,
    'originalPrice': null,
    'imageUrl':
        'https://toolorkg.com/wp-content/uploads/2025/03/WhatsApp-Image-2025-03-07-at-11.34.53.jpeg',
    'category': ProductCategory.men,
    'subcategory': ProductSubcategory.fleece,
    'description': 'Мужская флисовая куртка из мягкого и теплого флиса, отлично сохраняет тепло и не ограничивает движения. Легкая, воздухопроницаемая, подходит для активного отдыха. Застежка на молнии, удобные карманы на молнии, мягкие манжеты и низ для лучшей защиты от холода. Стильный и универсальный дизайн для г...',
    'sizes': ['M/L', 'S', 'XL'],
    'colors': ['Синий', 'Черный'],
  },
  {
    'id': 'men-035',
    'name': 'Мужская футболка',
    'price': 1599,
    'originalPrice': null,
    'imageUrl':
        'https://toolorkg.com/wp-content/uploads/2024/12/0F2A8313-1.jpg',
    'category': ProductCategory.men,
    'subcategory': ProductSubcategory.tshirts,
    'description': 'Классическая мужская футболка выполнена из мягкой хлопковой ткани, дополнена брендированной минималистичной вышивкой для простых, но всегда актуальных повседневных образов. Вдохновлено культурой номадов.  Особенности: *Круглый вырез воротника *Втачные короткие рукава *С минималистичной вышивкой р...',
    'sizes': ['S', 'M', 'L', 'XL', 'XXL'],
    'colors': ['Серый меланж', 'Темно-серый', 'Темно-синий'],
  },
  {
    'id': 'men-036',
    'name': 'Мужская футболка Wellness',
    'price': 1990,
    'originalPrice': null,
    'imageUrl':
        'https://toolorkg.com/wp-content/uploads/2025/09/IMG_5697_resized.jpeg',
    'category': ProductCategory.men,
    'subcategory': ProductSubcategory.tshirts,
    'description': 'В её простоте — честность и характер, а в вышивке гор Ала-Тоо — дыхание родной земли.   Футболка Wellness для тех, кто выбирает не просто одежду, а историю, вплетённую в каждую нить.   Особенности: *Прямой фасон *Втачные рукава *По центру груди круглая вышивка "Toolor Club"',
    'sizes': ['S', 'M', 'L', 'XL', 'XXL', '3XL'],
    'colors': ['Белый', 'Темно-синий'],
  },
  {
    'id': 'men-037',
    'name': 'Мужская футболка Оверсайз',
    'price': 1990,
    'originalPrice': null,
    'imageUrl':
        'https://toolorkg.com/wp-content/uploads/2024/12/0F2A9267-1-1.jpg',
    'category': ProductCategory.men,
    'subcategory': ProductSubcategory.tshirts,
    'description': 'Культура номада несет с собой свободную, заявляющую форму, как и наша мужская oversize футболка, изготовленая из хлопка, сочетает в себе комфорт и стиль в одном изделии.  Особенности: *Круглый вырез воротника *Втачные спущенные рукава *Oversize * Экологически безврредный принт *Представлена в дву...',
    'sizes': ['S', 'M', 'L', 'XL'],
    'colors': ['Кофе', 'Кремовый', 'Темно-синий'],
  },
  {
    'id': 'men-038',
    'name': 'Мужская футболка Юрта',
    'price': 1599,
    'originalPrice': null,
    'imageUrl':
        'https://toolorkg.com/wp-content/uploads/2024/12/0F2A9342-1.jpg',
    'category': ProductCategory.men,
    'subcategory': ProductSubcategory.tshirts,
    'description': 'Форма, линия, акцент. Футболка "Юрта" от Toolor олицетворяет уют и дом, который всегда с вами. Вдохновлена ​​кочевым образом жизни и обеспечивает чувство свободы и комфорта.  Особенности: *Круглый вырез воротника *Втачные короткие рукава * Рельефные швы * Брендирование вышивкой рунической надписи...',
    'sizes': ['S', 'M', 'L', 'XL', 'XXL'],
    'colors': ['Айвори', 'Графит', 'Черный'],
  },
  {
    'id': 'men-039',
    'name': 'Мужская футболка реглан с вышивкой',
    'price': 1990,
    'originalPrice': null,
    'imageUrl':
        'https://toolorkg.com/wp-content/uploads/2024/12/0F2A9174-1-1.jpg',
    'category': ProductCategory.men,
    'subcategory': ProductSubcategory.tshirts,
    'description': 'Мужская oversize футболка из хлопка. Функционально идентичен обычной футболке, но дополнен авторской работой объединяющий культурно-житейский уклад кочевников в современной интерпретации. Вдохновлено свободным Кыргызским народом.  Особенности: *Круглый вырез воротника *Рукава реглан *Оversize * Э...',
    'sizes': ['S', 'M', 'L', 'XL'],
    'colors': ['Бежевый', 'Кремовый', 'Темно-синий'],
  },
  {
    'id': 'men-040',
    'name': 'Мужская футболка реглан с принтом',
    'price': 1990,
    'originalPrice': null,
    'imageUrl':
        'https://toolorkg.com/wp-content/uploads/2024/12/0F2A7721-1-1.jpg',
    'category': ProductCategory.men,
    'subcategory': ProductSubcategory.tshirts,
    'description': 'Мужская oversize футболка из хлопка. Функционально идентичен обычной футболке, но дополнен авторской работой объединяющий культурно-житейский уклад кочевников в современной интерпретации. Вдохновлено свободным Кыргызским народом.  Особенности: *Круглый вырез воротника *Рукава реглан *Оversize * Э...',
    'sizes': ['S', 'M', 'L', 'XL'],
    'colors': ['Айвори', 'Кофе', 'Сине-зеленый'],
  },
  {
    'id': 'men-041',
    'name': 'Мужская футболка с принтом',
    'price': 1990,
    'originalPrice': null,
    'imageUrl':
        'https://toolorkg.com/wp-content/uploads/2024/12/0F2A9220-1-1.jpg',
    'category': ProductCategory.men,
    'subcategory': ProductSubcategory.tshirts,
    'description': 'Культура номада несет с собой свободную, заявляющую форму, как и наша мужская oversize футболка, изготовленая из хлопка, сочетает в себе комфорт и стиль в одном изделии.  Особенности: *Круглый вырез воротника *Втачные спущенные рукава *Oversize * Экологически безврредный принт *Представлена в дву...',
    'sizes': ['S', 'M', 'L', 'XL'],
    'colors': ['Айвори', 'Кофе', 'Сине-зеленый'],
  },
  {
    'id': 'men-042',
    'name': 'Мужская футболка-варенка',
    'price': 2800,
    'originalPrice': null,
    'imageUrl':
        'https://toolorkg.com/wp-content/uploads/2025/05/0F2A4989.jpg',
    'category': ProductCategory.men,
    'subcategory': ProductSubcategory.tshirts,
    'description': 'Футболка, будто выгоревшая на солнце приключений - мужская оверсайз модель с вареным эффектом создана для тех кто живет вне рамок. Выполнена из мягкого хлопкового трикотажа, она прошла специальную обработку, благодаря которой каждая вещь приобретает уникальный оттенок и текстуру. Свободный крой о...',
    'sizes': ['S', 'M', 'L', 'XL'],
    'colors': ['Графит'],
  },
  {
    'id': 'men-043',
    'name': 'Мужская футболка-варенка реглан',
    'price': 2800,
    'originalPrice': null,
    'imageUrl':
        'https://toolorkg.com/wp-content/uploads/2025/05/0F2A5083.jpg',
    'category': ProductCategory.men,
    'subcategory': ProductSubcategory.tshirts,
    'description': 'Футболка, будто выгоревшая на солнце приключений - мужская оверсайз модель с вареным эффектом создана для тех кто живет вне рамок. Выполнена из мягкого хлопкового трикотажа, она прошла специальную обработку, благодаря которой каждая вещь приобретает уникальный оттенок и текстуру. Свободный крой о...',
    'sizes': ['S', 'M', 'L', 'XL'],
    'colors': ['Голубой', 'Графит'],
  },
  {
    'id': 'men-044',
    'name': 'Мужское худи-балаклава',
    'price': 3800,
    'originalPrice': null,
    'imageUrl':
        'https://toolorkg.com/wp-content/uploads/2025/09/hudi-balaklava-scaled.jpg',
    'category': ProductCategory.men,
    'subcategory': ProductSubcategory.hoodies,
    'description': 'Худи-балаклава и брюки из трёхнитки — не просто комплект, а форма современного воина.  В городской среде он даёт свободу движения. На природе — защищает и становится частью ритма земли.  На спинке — древний орнамент Буркут в виде печати. Это знак силы, высоты и несломленного духа. Птица, что века...',
    'sizes': ['M', 'L', 'XL'],
    'colors': ['Графит', 'Черный'],
  },
  {
    'id': 'men-045',
    'name': 'Мужской худи',
    'price': 3600,
    'originalPrice': null,
    'imageUrl':
        'https://toolorkg.com/wp-content/uploads/2024/12/0F2A7393-1.jpg',
    'category': ProductCategory.men,
    'subcategory': ProductSubcategory.hoodies,
    'description': 'Мужская спортивная двойка худи-брюки с фирменным силуэтом и со встроенными потайными карманами.  Особенности: *Капюшон на шнуровке * Потайные карманы на свитшоте и на брюках * Низ рукава и брюк с манжетами * Свободный силуэт * Декоративная вышивка лого и рунической надписи «Кочевники будущего»',
    'sizes': ['S/M', 'M/L', 'L/XL'],
    'colors': ['Кармеланж', 'Темно-зеленый', 'Темно-синий', 'Черный'],
  },
  {
    'id': 'men-046',
    'name': 'Мужские шорты',
    'price': 2690,
    'originalPrice': null,
    'imageUrl':
        'https://toolorkg.com/wp-content/uploads/2025/05/0F2A7929-1-e1748472804610.jpg',
    'category': ProductCategory.men,
    'subcategory': ProductSubcategory.shorts,
    'description': 'Легкие шорты свободного кроя совмещает комфорт и утилитарность. Модель выполнена из практичной водоотталкивающей ткани и дополнена застежкой на кнопке с гульфиком. Эластичные вставки по бокам по линии талии адаптируются под фигуру, не сковывая движения. Функциональный акцент - задний карман на мо...',
    'sizes': ['S', 'M', 'L', 'XL'],
    'colors': ['Серый', 'Черный'],
  },
];

// ---------------------------------------------------------------------------
// Helper functions
// ---------------------------------------------------------------------------

/// Returns products filtered by category
List<Map<String, dynamic>> getProductsByCategory(String category) =>
    toolorProducts.where((p) => p['category'] == category).toList();

/// Returns products filtered by subcategory
List<Map<String, dynamic>> getProductsBySubcategory(String subcategory) =>
    toolorProducts.where((p) => p['subcategory'] == subcategory).toList();

/// Returns products on sale
List<Map<String, dynamic>> get saleProducts =>
    toolorProducts.where((p) => p['originalPrice'] != null).toList();

/// Returns a product by id
Map<String, dynamic>? getProductById(String id) {
  try {
    return toolorProducts.firstWhere((p) => p['id'] == id);
  } catch (_) {
    return null;
  }
}

/// Search products by query string
List<Map<String, dynamic>> searchProducts(String query) {
  final lowerQuery = query.toLowerCase();
  return toolorProducts
      .where(
        (p) =>
            (p['name'] as String).toLowerCase().contains(lowerQuery) ||
            (p['description'] as String).toLowerCase().contains(lowerQuery) ||
            (p['category'] as String).toLowerCase().contains(lowerQuery) ||
            (p['subcategory'] as String).toLowerCase().contains(lowerQuery),
      )
      .toList();
}

/// Returns all unique categories
List<String> get allCategories =>
    toolorProducts.map((p) => p['category'] as String).toSet().toList();

/// Returns all unique subcategories for a given category
List<String> getSubcategoriesForCategory(String category) =>
    toolorProducts
        .where((p) => p['category'] == category)
        .map((p) => p['subcategory'] as String)
        .toSet()
        .toList();

/// Returns the price range for the entire catalog
Map<String, int> get priceRange {
  final prices = toolorProducts.map((p) => p['price'] as int).toList();
  prices.sort();
  return {'min': prices.first, 'max': prices.last};
}
