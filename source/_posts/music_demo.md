---
title: 闲言碎语-07/20
date: 2022/07/20 10:00:00
categories: 闲言碎语
---

{% raw %}
<div class="aplayer" id="aplayer-lf"></div>
<script>
$(function () {
    $.ajax({
        url: 'https://api.i-meto.com/meting/api?server=netease&type=song&id=28535190',
        success: function (list) {
            var ap = new APlayer({
                element: document.getElementById('aplayer-lf'),
                showlrc: 3,
                theme: '#000',
                music: list[0]
            });
            window.aplayers || (window.aplayers = []);
            window.aplayers.push(ap);
        }
    })
})
</script>
{% endraw %}

没想到有一天，从我的嘴巴里也说出这种老套的话。

但，没办法否认的是，在这个快节奏社会，卷得厉害，为了不被抛弃，谁都不敢松懈，卷不动了依旧坚挺着，压力都是有的。

我们的身体跟我们一起承担着这份压力，我深知，它撑得很辛苦。

我也是。因为辛苦，所以更有必要善待它。