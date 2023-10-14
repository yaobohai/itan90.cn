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