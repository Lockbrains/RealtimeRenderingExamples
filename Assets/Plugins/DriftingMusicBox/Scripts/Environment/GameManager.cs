using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;
public class GameManager : MonoBehaviour
{
    public enum GameStatus
    {
        BeforeStart,
        GameStart,
        GamePause
    }

    public static GameManager S;
    public GameStatus status;
    
    private void Awake()
    {
        S = this;
    }
    // Start is called before the first frame update
    void Start()
    {
        
    }

    // Update is called once per frame
    void Update()
    {
        
    }
}
